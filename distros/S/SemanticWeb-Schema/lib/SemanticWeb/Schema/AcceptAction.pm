package SemanticWeb::Schema::AcceptAction;

# ABSTRACT: <p>The act of committing to/adopting an object

use Moo;

extends qw/ SemanticWeb::Schema::AllocateAction /;


use MooX::JSON_LD 'AcceptAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AcceptAction - <p>The act of committing to/adopting an object

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of committing to/adopting an object.</p> <p>Related actions:</p>
<ul> <li><a class="localLink"
href="http://schema.org/RejectAction">RejectAction</a>: The antonym of
AcceptAction.</li> </ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::AllocateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
