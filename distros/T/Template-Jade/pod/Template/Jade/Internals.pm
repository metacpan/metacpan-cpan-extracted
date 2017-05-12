=head1 NAME

Template::Jade::Internals - Perl Template Engine

=head1 Format of parser

As of now the parser is recursive descent. The function B<process_tree> does
the bulk of the work. The parser is also stream based. The very subroutine is
created by printing to a stream.
