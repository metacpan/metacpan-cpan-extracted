package SemanticWeb::Schema::RejectAction;

# ABSTRACT: <p>The act of rejecting to/adopting an object

use Moo;

extends qw/ SemanticWeb::Schema::AllocateAction /;


use MooX::JSON_LD 'RejectAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::RejectAction - <p>The act of rejecting to/adopting an object

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of rejecting to/adopting an object.</p> <p>Related actions:</p>
<ul> <li><a class="localLink"
href="http://schema.org/AcceptAction">AcceptAction</a>: The antonym of
RejectAction.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::AllocateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
