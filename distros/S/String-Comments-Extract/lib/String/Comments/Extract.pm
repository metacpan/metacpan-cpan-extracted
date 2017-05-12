package String::Comments::Extract;
BEGIN {
  $String::Comments::Extract::VERSION = '0.023';
}
# ABSTRACT: Extract comments from C/C++/JavaScript/Java source

use warnings;
use strict;

use XSLoader;

XSLoader::load(
    __PACKAGE__,
    # We need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $String::Comments::Extract::{VERSION} ? ${ $String::Comments::Extract::{VERSION} } : (), 
);

use String::Comments::Extract::SlashStar;
use String::Comments::Extract::C;
use String::Comments::Extract::CPP;
use String::Comments::Extract::JavaScript;
use String::Comments::Extract::Java;


1; # End of String::Comments::Extract

__END__
=pod

=head1 NAME

String::Comments::Extract - Extract comments from C/C++/JavaScript/Java source

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use String::Comments::Extract;

    my $source = <<_END_
    /* A Hello World program
    
        Copyright Ty Coon
        // ...and Buckaroo Banzai
      "Yoyodyne"*/

    void main() {
        printf("Hello, World.\n");
        printf("/* This is not a real comment */");
        printf("// Neither is this */");
        // But this is
    }

    // Last comment
    _END_

    my $comments = String::Comments::Extract::C->extract($source)
    # ... returns the following result:

        /* A Hello World program
        
            Copyright Ty Coon
            // ...and Buckaroo Banzai
          "Yoyodyne"*/

          
            
            
            
            // But this is
        

        // Last comment

    my @comments = String::Comments::Extract::C->collect($source)
    # ... returns the following list:
        (
' A Hello World program
    
        Copyright Ty Coon
        // ...and Buckaroo Banzai
      "Yoyodyne"',
            ' But this is',
            ' Last comment',
        )

=head1 DESCRIPTION

String::Comments::Extract is a tool for extracting comments from C/C++/JavaScript/Java source. The extractor
is implemented using an actual tokenizer (written in C via XS [adapted from L<JavaScript::Minifier::XS>]). By using
a tokenizer, it can correctly deal with notoriously problematic cases, such as comment-like structures embedded in strings:

    std::cout << "This is not a // real C++ comment " << std::endl
    printf("/* This is not a real C comment */\n");
    # The extractor will ignore both of the above

String::Comments::Extract considers C/C++/JavaScript/Java comment structures the same, so, for now, it doesn't really
matter which method you use (this means it will not complain about C++ style comments in C source).

The language agnostic interface to C/C++/JavaScript/Java comment extractor is accessible via String::Comments::Extract::SlashStar

    # Can handle slash-star (/* */) and slash-slash (//) comments
    String::Comments::Extract::SlashStar->extract
    String::Comments::Extract::SlashStar->collect

=head1 METHODS

=head2 String::Comments::Extract::JavaScript->extract( <source> )

=head2 String::Comments::Extract::CPP->extract( <source> )

=head2 String::Comments::Extract::C->extract( <source> )

=head2 String::Comments::Extract::SlashStar->extract( <source> )

Returns a string representing the comments in <source>

Comment delimeters ( C</* */ //> ) are left in as-is

Whitespace of <source> is otherwise preserved, so you'll probably have to do some post-processing to get rid of some cruft.

=head2 String::Comments::Extract::JavaScript->collect( <source> )

=head2 String::Comments::Extract::CPP->collect( <source> )

=head2 String::Comments::Extract::C->collect( <source> )

=head2 String::Comments::Extract::SlashStar->collect( <source> )

Returns a list containing an item for each block- or line-comment in <source>

Comment delimeters ( C</* */ //> ) around the comment are removed

Whitespace outside of comments may not be preserved exactly

=head1 SEE ALSO

L<File::Comments>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

