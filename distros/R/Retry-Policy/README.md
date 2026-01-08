# NAME

Retry::Policy - Simple retry wrapper with exponential backoff and jitter

# SYNOPSIS

    use Retry::Policy;

    my $p = Retry::Policy->new(
        max_attempts  => 5,
        base_delay_ms => 100,
        max_delay_ms  => 10_000,
        jitter        => 'full',
    );

    my $value = $p->run(sub {
        my ($attempt) = @_;
        die "transient\n" if $attempt < 3;
        return "ok";
    });

# DESCRIPTION

Small, dependency-light retry helper for backend and system code where
transient failures are expected.

# DESIGN NOTES

- Exponential backoff with a maximum cap is a common production default for transient failures.
- Full jitter helps avoid synchronized retries (thundering herd) across multiple workers or hosts.
- Defaults are intentionally conservative; callers should tune retry behavior per dependency (database, HTTP service, filesystem, etc.).
- Validation is strict: invalid configurations fail fast rather than producing undefined retry behavior.

# PRACTICAL USE CASES

## Retry a flaky HTTP call (transient network or service errors)

    use Retry::Policy;

    my $p = Retry::Policy->new(
        max_attempts  => 6,
        base_delay_ms => 200,
        max_delay_ms  => 5000,
        retry_on      => sub {
            my ($err) = @_;
            return ($err =~ /timeout|temporarily unavailable|connection reset/i) ? 1 : 0;
        },
    );

    my $body = $p->run(sub {
        # Replace this block with your HTTP client of choice
        die "timeout\n" if rand() < 0.2;
        return "ok";
    });

## Retry a database connection (DBI)

    use DBI;
    use Retry::Policy;

    my $p = Retry::Policy->new(
        max_attempts  => 5,
        base_delay_ms => 250,
        max_delay_ms  => 8000,
        retry_on      => sub {
            my ($err) = @_;
            return ($err =~ /server has gone away|lost connection|timeout/i) ? 1 : 0;
        },
    );

    my $dbh = $p->run(sub {
        my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0 });
        return $dbh;
    });

## Retry acquiring a lock or contended resource

    use Fcntl qw(:flock);
    use Retry::Policy;

    my $p = Retry::Policy->new(
        max_attempts  => 20,
        base_delay_ms => 50,
        max_delay_ms  => 1000,
        retry_on      => sub { 1 }, # lock contention is typically transient
    );

    $p->run(sub {
        open my $fh, ">>", "/tmp/my.lock" or die "open lock: $!\n";
        flock($fh, LOCK_EX | LOCK_NB) or die "lock busy\n";
        # work while lock held
        return 1;
    });

# LICENSE

Same terms as Perl itself.
