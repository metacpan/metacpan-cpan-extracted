# Gate: a form behind a proof-of-work challenge

The example application for [Punk::Plugin::Challenge](https://metacpan.org/pod/Punk::Plugin::Challenge).
Generated with `punk new Gate` and then given two rules.

```
export GATE_CHALLENGE_KEY=$(punk challenge key)
export GATE_SESSION_KEY=$(punk challenge key)
plackup -s Hyperman app.psgi   # -s, lowercase: -S is a socket
prove -l t/
```

The two secrets come from the environment; `config/punk.yml` references
them and never holds them. The challenge secret is never generated for you,
because a pool of workers would each mint their own and refuse each other's
clearances.

Then:

| URL | |
|---|---|
| <http://localhost:5000/> | the page that explains, free |
| <http://localhost:5000/login> | the form, behind an `always` rule |
| <http://localhost:5000/api/time> | JSON, behind an `after` rule |

`app.psgi` and `t/01-basic.t` add the distribution's `blib` to `@INC` so
the demo runs before `Punk::Challenge` is installed. Drop those lines once
it is.

## What to look at

**The form is behind `always`.** Open `/login` in a browser and the first
thing you see is "One moment". The page carries the puzzle in a data
attribute and loads `/challenge/challenge.js`, which solves it in a Worker,
posts the solution, and reloads with a clearance cookie that holds for an
hour. Open it on a phone too: the difficulty is paid by the slowest phone of
your slowest legitimate user, and the number in `lib/Gate.pm` is only right
if that phone clears it in a moment.

**The API is behind `after`.** `/api/time` is free for thirty requests a
minute per /24, and a puzzle past that instead of a `429`. The counter
lives in Hyperman's shared arena; under any other server there is none,
the rule is inert, and the application says so once, at the first request
under the rule. Run it with `plackup -s Hyperman` and hit it thirty-one
times.

**From a shell.** A program gets JSON, not a page:

```
curl -si http://localhost:5000/login | grep X-Challenge
punk challenge solve <the puzzle>
curl -si -H 'X-Challenge-Response: <the solution>' http://localhost:5000/login
```

**csrf is on, and verify is not checked by it.** The sign-in form carries a
token; the challenge's own verify route is a `POST` without a session that
changes nothing but its own cookie, so the plugin exempts it and nothing in
`config/punk.yml` says so.

**No `proxy` line.** The demo is served directly. Behind nginx, an ELB or a
CDN, `proxy;` is the first line after `use Punk`, or every visitor on the
internet is one subject and one solve clears them all.
