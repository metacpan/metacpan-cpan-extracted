package Template::Alloy::XS;

=head1 NAME

Template::Alloy::XS - XS version of key parts of Template::Alloy

=cut

use strict;
use warnings;
use XSLoader;
use v5.8.0;
use Template::Alloy 1.015;
use base qw(Template::Alloy);

our $VERSION = '1.004';
XSLoader::load('Template::Alloy::XS', $VERSION);

### method used for debugging XS
sub __dump_any {
    my ($self, $data) = @_;
    require Data::Dumper;
    print Data::Dumper::Dumper($data);
}

### this is here because I don't know how to call
### builtins from XS - anybody know how?
sub __lc { lc $_[0] }

sub play_tree {
    my $self = shift;
    return $self->stream_tree(@_) if $self->{'STREAM'};
    require Template::Alloy::Play;
    $self->play_tree_xs(@_);
}

1;

__END__


=head1 SYNOPSIS

    use Template::Alloy::XS;

    my $obj = Template::Alloy::XS->new;

    # see the Template::Alloy documentation

=head1 DESCRIPTION

This module allows key portions of the Template::Alloy module to run in XS.

All of the methods of Template::Alloy are available.  All configuration
parameters, and all output should be the same.  You should be able
to use this package directly in place of Template::Alloy.

=head1 BUGS/TODO

=over 4

=item Add play_variable

With the compile_perl option we added play_variable which is a partially
resolved variable mapper - more closely associated with Template::Stash's
get method.  We need to recreate the method here.

=item Memory leak

The use of FILTER aliases causes a memory leak in a cached environment.
The following is an example of a construct that can cause the leak.

  [% n=1; n FILTER echo=repeat(2); n FILTER echo %]

Anybody with input or insight into fixing the code is welcome to submit
a patch :).

=item undefined_any

The XS version doesn't call undefined_any when play_expr finds an
undefined value.  It needs to.

=back

=head1 AUTHOR

Paul Seamons, E<lt>paul@seamons.comE<gt>

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=cut
