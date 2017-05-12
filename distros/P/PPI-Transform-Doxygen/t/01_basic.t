use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use Fcntl qw(:seek);

BEGIN {
    push @INC, "$Bin/../lib";
    for my $mod ('PPI', 'PPI::Transform::Doxygen') {
        use_ok($mod, "load $mod") or BAIL_OUT("cannot load $mod");
    }
};

my $tr = new_ok('PPI::Transform::Doxygen');

open(my $out, '>', \my $buf);

$tr->file("$Bin/../Makefile.PL" => $out);

like($buf, qr/class\ Makefile_main:\ public/, 'no pod');

seek($out, 0, SEEK_SET);

#diag $buf;

$tr->file($0 => $out);

#diag($buf);

my $fhead = quotemeta('/** @file 01_basic.t');
my($fcontent) = $buf =~ m!$fhead\n(.+?)\*/!s;

isnt($fcontent, undef, 'file section');

like($fcontent, qr!\@section DESCRIPTION DESCRIPTION\n<p>txt1</p>!, 'head1');

my $chead = quotemeta('class 01_basic_main: public {');
my($ccontent) = $buf =~ m!$chead\n(.+?)\};!s;

isnt($ccontent, undef, 'class section');

my($cpublic, $cprivate) = $ccontent =~ m!public:(.+)private:(.+)$!s;

isnt($cpublic, undef, 'public section');
isnt($cprivate, undef, 'private section');

my $fn = quotemeta('virtual void a_func()');

like($cpublic, qr!\*\*\ \@fn\ $fn\n.+\*/\n$fn;\n!s, 'a_func');

like($cprivate, qr/^\s*$/, 'only public');

done_testing();

=head2 class_method $obj new(%args)

Creates a new THINGY object

=cut
sub new {
    my($class, %args) = @_;
    return bless(\%args, $class);
}

__END__

=pod

=head1 DESCRIPTION

txt1

=cut

=head2 a_func()

txt_a_func()

=cut

