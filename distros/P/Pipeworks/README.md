# NAME

Pipeworks - Pipeline Processing Framework

# SYNOPSIS

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

# DESCRIPTION

This is a message oriented pipeline processing framework to
enable separation of concerns, organization of individual functionality
and improve code-reuse though aspect orientation.

It simply allows to define and organize pipelines that process
messages in multiple steps and return a result.

# HISTORY

Originally the basic idea is inspired by UNIX concepts.
There was a lot of thinking how to represent a similar model in programming
without losing important benefits that UNIX provides.
When Steve Bate wrote a blog post about [Messaging as a Programming Model](http://eventuallyconsistent.net/2013/08/12/messaging-as-a-programming-model-part-1/)
things came together, started to make sense and code began to materialize this
implementation.

# SEE ALSO

[http://eventuallyconsistent.net/2013/08/12/messaging-as-a-programming-model-part-1/](http://eventuallyconsistent.net/2013/08/12/messaging-as-a-programming-model-part-1/),
[http://eventuallyconsistent.net/2013/08/14/messaging-as-a-programming-model-part-2/](http://eventuallyconsistent.net/2013/08/14/messaging-as-a-programming-model-part-2/),
[http://eventuallyconsistent.net/2013/08/19/messaging-as-a-programming-model-revisited/](http://eventuallyconsistent.net/2013/08/19/messaging-as-a-programming-model-revisited/),
[http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/messaging-for-more-decoupling.aspx](http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/messaging-for-more-decoupling.aspx),
[http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/17/messaging-as-a-programming-model-ndash-letacutes-get-real.aspx](http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/17/messaging-as-a-programming-model-ndash-letacutes-get-real.aspx),
[http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/18/flows-ndash-visualizing-the-messaging-programming-model.aspx](http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/18/flows-ndash-visualizing-the-messaging-programming-model.aspx),
[http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/nested-messaging---flows-on-different-levels-of-abstraction.aspx](http://geekswithblogs.net/theArchitectsNapkin/archive/2013/08/19/nested-messaging---flows-on-different-levels-of-abstraction.aspx)

# AUTHOR

Simon Bertrang <janus@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2013 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
