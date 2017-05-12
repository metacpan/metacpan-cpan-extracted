package Pipeworks;

use strict;
use warnings;

our $VERSION = '0.04';

1;

__END__

=head1 NAME

Pipeworks - Pipeline Processing Framework

=head1 SYNOPSIS

  use Pipeworks::Pipeline::MyDoc;
  use Pipeworks::Message::GetBody;
  
  my $line = Pipeworks::Pipeline::MyDoc->new;
  
  # same as Pipeworks::Stage::FetchURL->new( ... )
  $line->register( 'FetchURL' );
  $line->register( 'GetDocumentBody' );
  $line->register( sub { my $msg = shift; warn( "body:\n" . $msg->body ) } );
  
  # same as Pipeworks::Message::GetBody->new( ... )
  my $message = $line->message( GetBody => {
    url => 'http://localhost/',
  } );
  my $result = $line->process( $message );

=head1 DESCRIPTION

This is a message oriented pipeline processing framework to
enable separation of concerns, organization of individual functionality
and improve code-reuse though aspect orientation.

It simply allows to define and organize pipelines that process
messages in multiple steps and return a result.

=head1 HISTORY

Originally the basic idea is inspired by UNIX concepts.
There was a lot of thinking how to represent a similar model in programming
without losing important benefits that UNIX provides.
When Steve Bate wrote a blog post about L<Messaging as a Programming Model|http://eventuallyconsistent.net/2013/08/12/messaging-as-a-programming-model-part-1/>
things came together, started to make sense and code began to materialize this
implementation.

=head1 SEE ALSO

L<http://eventuallyconsistent.net/2013/08/12/messaging-as-a-programming-model-part-1/>,
L<http://eventuallyconsistent.net/2013/08/14/messaging-as-a-programming-model-part-2/>,
L<http://eventuallyconsistent.net/2013/08/19/messaging-as-a-programming-model-revisited/>,
L<http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/messaging-for-more-decoupling.aspx>,
L<http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/17/messaging-as-a-programming-model-ndash-letacutes-get-real.aspx>,
L<http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/18/flows-ndash-visualizing-the-messaging-programming-model.aspx>,
L<http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/nested-messaging---flows-on-different-levels-of-abstraction.aspx>

=head1 AUTHOR

Simon Bertrang E<lt>janus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

