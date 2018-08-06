package SemanticWeb::Schema::FindAction;

# ABSTRACT: <p>The act of finding an object

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'FindAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::FindAction - <p>The act of finding an object

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html <p>The act of finding an object.</p> <p>Related actions:</p> <ul> <li><a
class="localLink" href="http://schema.org/SearchAction">SearchAction</a>:
FindAction is generally lead by a SearchAction, but not necessarily.</li>
</ul> 

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
