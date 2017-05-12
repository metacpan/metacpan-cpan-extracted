package Parse::CPAN::Authors::Author;
use strict;
use base qw( Class::Accessor::Fast );
 __PACKAGE__->mk_accessors(qw( pauseid name email ));

1;

__END__

=head1 NAME

Parse::CPAN::Authors::Author - Represent a CPAN author

=head1 SYNOPSIS

  # ... objects are returned by Parse::CPAN::Authors
  my $author = $p->author('LBROCARD');
  print $author->email, "\n";   # leon@astray.com
  print $author->name, "\n";    # Leon Brocard
  print $author->pauseid, "\n"; # LBROCARD

=head1 DESCRIPTION

This represents a CPAN author.

=head1 METHODS

=head2 new()

The new() method is used by Parse::CPAN::Authors to create author
objects. You should not need to create them on your own.

=head2 email()

The email() method returns the email of the author.

=head2 name()

The name() method returns the name of the author.

=head2 pauseid()

The pauseid() method returns the Perl Authors Upload Server ID of the
author.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2004, Leon Brocard

This module is free software; you can redistribute it or modify it under
the same terms as Perl itself.
