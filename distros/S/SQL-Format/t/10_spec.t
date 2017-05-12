use strict;
use warnings;
use t::Util;
use Test::More;
use SQL::Format;

my $spec;
open my $fh, '<', 'lib/SQL/Format/Spec.pod' or die $!;
while (defined(my $line = <$fh>)) {
    chomp $line;
    $line =~ s/^\s*|\s*$//;

    last if $line =~ /^=cut/;
    next unless $line =~ /^=head2 (.*)/ || $spec;
    $spec = $1 || $spec;

    next if $line =~ /^\s*$/;
    next unless $line =~ s/^# //;

    my $desc           = $line;
    my $input          = <$fh>;
    my @params         = _eval(scalar <$fh>);
    my $expected       = <$fh>;
    my $expected_binds = _eval(scalar <$fh>);

    subtest "$spec: $desc" => sub {
        my ($stmt, @bind) = sqlf $input, @params;
        is $stmt, $expected;
        is_deeply \@bind, $expected_binds;
    };
}

sub _eval {
    my $line = shift;
    my $wantarray = wantarray;
    my $data = $wantarray ? [ eval "$line" ] : eval "$line";
    if ($@) {
        fail "$@: syntax error at line $.";
        exit;
    }
    return $wantarray ? @$data : $data;
}

done_testing;
