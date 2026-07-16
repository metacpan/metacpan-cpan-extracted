use v5.40;
use experimental 'signatures';
use Future;
use Future::AsyncAwait;
use Future::IO;
use JSON::MaybeXS qw(encode_json);
use PAGI::Nano;

# *** Real-time multiplayer Conway's Game of Life, in one small file. ***
#
# A background ticker evolves one shared world on the event loop. Every
# generation is broadcast over Server-Sent Events to all connected browsers at
# once, and anyone can POST to bring a cell to life — which everyone then sees in
# the very next frame. Open it in two tabs and watch them stay in lockstep; click
# in one and life appears in the other. A live, multiplayer cellular automaton
# with no database, no message broker, no JS framework — just PAGI::Nano.
#
#     pagi-server app.pl
#     # then open http://127.0.0.1:5000/ in two browser windows and click around
#
#     # or watch the raw frames stream by:
#     curl -N http://127.0.0.1:5000/live
#     # and inject a cell from another terminal:
#     curl -X POST http://127.0.0.1:5000/cell/10/10

my ($W, $H) = (48, 28);

# --- the world: a toroidal grid evolving by Conway's rules --------------------
package GoL::World {
    use experimental 'signatures';

    sub new ($class, $w, $h) {
        bless { w => $w, h => $h, gen => 0,
                cells => [ map { [ (0) x $w ] } 1 .. $h ] }, $class;
    }

    sub toggle ($self, $x, $y) {
        return unless $x >= 0 && $x < $self->{w} && $y >= 0 && $y < $self->{h};
        $self->{cells}[$y][$x] ^= 1;
    }

    sub _alive ($self, $x, $y) {
        $self->{cells}[ ($y + $self->{h}) % $self->{h} ][ ($x + $self->{w}) % $self->{w} ];
    }

    sub step ($self) {
        my @next;
        for my $y (0 .. $self->{h} - 1) {
            my @row;
            for my $x (0 .. $self->{w} - 1) {
                my $n = 0;
                for my $dy (-1, 0, 1) {
                    for my $dx (-1, 0, 1) {
                        next if $dx == 0 && $dy == 0;
                        $n += $self->_alive($x + $dx, $y + $dy);
                    }
                }
                my $live = $self->{cells}[$y][$x];
                push @row, (($live ? ($n == 2 || $n == 3) : ($n == 3)) ? 1 : 0);
            }
            push @next, \@row;
        }
        $self->{cells} = \@next;
        $self->{gen}++;
    }

    # Drop a classic glider with its top-left at ($ox, $oy).
    sub seed_glider ($self, $ox, $oy) {
        $self->toggle($ox + $_->[0], $oy + $_->[1])
            for ([1, 0], [2, 1], [0, 2], [1, 2], [2, 2]);
    }

    # A wire-friendly snapshot: each row is a string of 0/1 characters.
    sub frame ($self) {
        {
            generation => $self->{gen},
            w => $self->{w}, h => $self->{h},
            rows => [ map { join '', @$_ } @{ $self->{cells} } ],
        };
    }
}

# --- a broadcast hub: one Future per waiting client, all resolved per tick -----
package GoL::Hub {
    use experimental 'signatures';
    use Future;

    sub new ($class) { bless { waiters => [] }, $class }

    sub next_frame ($self) {
        my $f = Future->new;
        push @{ $self->{waiters} }, $f;
        $f;
    }

    sub publish ($self, $frame) {
        my @waiters = @{ $self->{waiters} };
        $self->{waiters} = [];
        $_->done($frame) for @waiters;
    }
}

our $HTML;   # the live client, defined at the foot of the file

my $app = app {
    startup async sub ($state) {
        my $world = GoL::World->new($W, $H);
        $world->seed_glider(2, 2);
        $world->seed_glider(20, 10);
        $world->seed_glider(35, 4);

        my $hub = GoL::Hub->new;
        $state->{world} = $world;
        $state->{hub}   = $hub;

        # The single source of motion: step the world and broadcast, forever.
        # Retained (not awaited) so it runs on the loop for the app's lifetime.
        $state->{ticker} = (async sub {
            while (1) {
                await Future::IO->sleep(0.3);
                $world->step;
                $hub->publish($world->frame);
            }
        })->();
    };

    get '/' => sub ($c) { $c->html($HTML) };

    # A plain JSON snapshot — for curl, tests, or a non-streaming client.
    get '/grid' => sub ($c) { $c->state->{world}->frame };

    # Bring a cell to life (or kill it). The change rides out on the next frame
    # that every connected client receives — that is the whole multiplayer trick.
    post '/cell/:x/:y' => sub ($c, $x, $y) {
        $c->state->{world}->toggle(int($x), int($y));
        $c->json({ ok => 1 }, status => 202);
    };

    # The live feed: send the current frame now, then one per generation until
    # the client goes away.
    sse '/live' => async sub ($c) {
        my $hub = $c->state->{hub};
        my $s   = $c->sse;
        await $s->send_event(event => 'frame', data => encode_json($c->state->{world}->frame));
        while (!$c->is_disconnected) {
            my $frame = await $hub->next_frame;
            last if $c->is_disconnected;
            await $s->send_event(event => 'frame', data => encode_json($frame));
        }
    };
};

# --- the live client: EventSource in, canvas out, clicks back out -------------
$HTML = <<'HTML';
<!doctype html>
<meta charset="utf-8">
<title>PAGI::Nano — Multiplayer Life</title>
<style>
  body { background:#0b0e14; color:#cdd9e5; font:14px/1.5 ui-monospace,monospace; text-align:center; margin:2rem }
  h1 { font-weight:600; letter-spacing:.04em }
  canvas { background:#11151c; border:1px solid #2a3550; border-radius:6px; cursor:crosshair; image-rendering:pixelated }
  .meta { margin:.6rem; color:#7b8aa8 }
  b { color:#6cf09a }
</style>
<h1>PAGI::Nano · Multiplayer Game of Life</h1>
<div class="meta">generation <b id="gen">0</b> — click to seed life; open another tab to play along</div>
<canvas id="c"></canvas>
<script>
const cell = 14;
const cv = document.getElementById('c'), ctx = cv.getContext('2d');
let W = 0, H = 0;

function draw(frame) {
  W = frame.w; H = frame.h;
  if (cv.width !== W*cell) { cv.width = W*cell; cv.height = H*cell; }
  ctx.fillStyle = '#11151c'; ctx.fillRect(0, 0, cv.width, cv.height);
  ctx.fillStyle = '#6cf09a';
  for (let y = 0; y < H; y++) {
    const row = frame.rows[y];
    for (let x = 0; x < W; x++)
      if (row[x] === '1') ctx.fillRect(x*cell+1, y*cell+1, cell-2, cell-2);
  }
  document.getElementById('gen').textContent = frame.generation;
}

const es = new EventSource('/live');
es.addEventListener('frame', e => draw(JSON.parse(e.data)));

cv.addEventListener('click', e => {
  const r = cv.getBoundingClientRect();
  const x = Math.floor((e.clientX - r.left) / cell);
  const y = Math.floor((e.clientY - r.top) / cell);
  fetch(`/cell/${x}/${y}`, { method: 'POST' });
});
</script>
HTML

$app;
