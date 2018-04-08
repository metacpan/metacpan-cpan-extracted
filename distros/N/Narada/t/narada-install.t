use lib 't'; use share; guard my $guard;

require (wd().'/blib/script/narada-install');


sub is_version;
sub is_backups;


# - simple functional test:
#       0.0.0 upgrade to   0.1.0
#   * check is VERSION file created and correct
#   * check there are no backups
is_version '0.1.0';
is_backups [], 'no backups';
#       0.1.0 downgrade to 0.0.0
#   * check is VERSION file removed
#   * check backup for 0.1.0 created
lives_ok { output_from { main(qw( --allow-downgrade 0.0.0 )) } } '0.0.0';
is_version '0.0.0';
is_backups [qw( full-0.1.0 )];
unlink '.backup/full-0.1.0.tar' or die "unlink: $!";
#       0.0.0 upgrade to   1.1.0
#   * check is VERSION file created and correct
#   * check backup for 0.1.0 created
output_from { main(qw( -f .release/0.1.0.migrate 1.1.0 )) };
is_version '1.1.0';
is_backups [qw( full-0.1.0 )];
#       1.1.0 upgrade to   1.2.0
#   * check is VERSION file modified and correct
#   * check backup for 1.1.0 created
output_from { main(qw( 1.2.0 )) };
is_version '1.2.0';
is_backups [qw( full-0.1.0 full-1.1.0 )];
#       1.2.0 downgrade to 0.0.0
#   * check is VERSION file removed
#   * check backup for 1.2.0 created
#   * check backup for 1.1.0 updated
my $old_size = -s '.backup/full-1.1.0.tar';
output_from { main(qw( -D -f .release/0.1.0.migrate 0.0.0 )) };
is_version '0.0.0';
is_backups [qw( full-0.1.0 full-1.1.0 full-1.2.0 )];
# XXX incremental archives was disabled
# ok -s '.backup/full-1.1.0.tar' > $old_size, 'full-1.1.0 updated';


done_testing();


sub is_version {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ($_[0] eq '0.0.0') {
        ok !path('VERSION')->exists, 'no VERSION';
    }
    elsif (path('VERSION')->exists) {
        my ($v) = path('VERSION')->lines({chomp=>1});
        is $v, $_[0], $_[1] // "version: $_[0]";
    }
    else {
        ok 0, $_[1] // "version: $_[0]";
    }
}

sub is_backups {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply [ sort map { $_->basename('.tar') }
        path('.backup')->children(qr/\A(?!full[.]tar\z|incr[.]tar\z|snap\z)/ms)
        ], $_[0], $_[1] // "backups: @{$_[0]}";
}
