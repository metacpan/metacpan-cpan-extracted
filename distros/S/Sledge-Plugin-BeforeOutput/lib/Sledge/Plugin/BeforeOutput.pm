package Sledge::Plugin::BeforeOutput;

use strict;
no strict 'refs';
use vars qw($VERSION);
$VERSION = 0.03;

sub import {
    my $class = shift;

    ## switch by Class::Trigger version.
    my ($ct_version,$ct_detail_version) = $Class::Trigger::VERSION =~/^([0-9.]+)(?:_|)([0-9]*)$/;

    if( $ct_version > 0.10 || ( $ct_version >= 0.10 && $ct_detail_version ) ) {
        $Class::Trigger::Triggers{'Sledge::Pages::Base'}->{BEFORE_OUTPUT} = 1;
    } else {
        Sledge::Pages::Base->__triggerpoints->{BEFORE_OUTPUT} = 1;
    }

    {
        no warnings qw/redefine/;
        my $output_content_method = \&Sledge::Pages::Base::output_content;
        *{'Sledge::Pages::Base::output_content'} = sub {
            my $self = shift;
            unless ($self->finished) {
                $self->invoke_hook('BEFORE_OUTPUT');
                &$output_content_method($self);
            }
        };
    }
}

1;
__END__

=head1 NAME

Sledge::Plugin::BeforeOutput - add trigger before outout plugin for Sledge.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

=head2 Sledge Controller Class

  package YourProj::Pages::Foo;
  
  use Sledge::Plugin::BeforeOutput;

  __PACKAGE__->register_hook (
      BEFORE_OUTPUT => sub {
          my $self = shift;
          ## do something.
      }
  );
  
  sub dispatch_index {
      my $self = shift;
  }
  ...


=head1 DESCRIPTION

This module adds BEFORE_OUTPUT hook to Sledge. 

BEFORE_OUTPUT is carried out between AFTER_DISPATCH and AFTER_OUTPUT,
that is step before Template rendering start.

=head1 EXAMPLE

An example with L<Sledge::Plugin::Stash>

  package YourProj::Pages::Foo;
  
  use Sledge::Plugin::BeforeOutput; ## You must declare it earlier than other plugin.
  use Sledge::Plugin::Stash;
  
  sub dispatch_index {
      my $self = shift;
      $self->stash->{foo} = 'bar';
  }
  ...


=head1 SEE ALSO

L<Class::Trigger>

L<Sledge::Plugin::Stash> L<Sledge::Plugin::URIWith> L<Sledge::Plugin::DebugMessage>


=head1 BUGS

Please report any bugs or suggestions at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sledge-Plugin-BeforeOutput>


=head1 AUTHOR

syushi matsumoto, C<< <matsumoto at alink.co.jp> >>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Alink INC. all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

