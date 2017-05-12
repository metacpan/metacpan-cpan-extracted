package Template::Declare::Bricolage;

use strict;
our $VERSION = '0.01';

BEGIN {
    eval 'package ' . __PACKAGE__ . q{::OneTag;
        $INC{'Template/Declare/Bricolage/OneTag.pm'} = __FILE__;
        use base 'Template::Declare::TagSet';
        sub get_tag_list { [ 'assets' ] }
    };
}

use base 'Template::Declare';
use Template::Declare::Tags 'OneTag', { from => __PACKAGE__ . '::OneTag' };

my $ns = 'http://bricolage.sourceforge.net/assets.xsd';

template go => sub {
    my $code = pop;
    xml_decl { 'xml', version => '1.0', encoding => 'utf-8' };
    assets {
        attr { xmlns => $ns };
        $code->();
    }
};

sub bricolage(&) {
    Template::Declare->init( roots => [__PACKAGE__] );
    Template::Declare->show( go => shift );
}

sub import {
    my $pkg = shift;
    my $caller = caller;
    no strict 'refs';
    return shift if defined &{"$caller\::bricolage"};
    *{"$caller\::bricolage"} = \&bricolage;
    @_ = qw(Template::Declare::Tags Bricolage);
    goto &Template::Declare::Tags::import;
}

1;
__END__

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 NAME

Template::Declare::Bricolage - Perlish XML Generation for Bricolage's SOAP API

=end comment

=head1 Name

Template::Declare::Bricolage - Perlish XML Generation for Bricolage's SOAP API

=head1 Synopsis

  use Template::Declare::Bricolage;

  say bricolage {
      workflow {
          attr        { id => 1027     };
          name        { 'Blogs'        }
          description { 'Blog Entries' }
          site        { 'Main Site'    }
          type        { 'Story'        }
          active      { 1              }
          desks  {
              desk { attr { start   => 1 }; 'Blog Edit'    }
              desk { attr { publish => 1 }; 'Blog Publish' }
          }
      }
  };

=head1 Description

It can be a lot of work generating XML for passing to the Bricolage SOAP
interface. After experimenting with a number of XML-generating libraries, I
got fed up and created this module to simplify things. It's a very simple
subclass of L<Template::Declare|Template::Declare> that supplies a functional
interface to templating your XML. All the XML elements understood by the
Bricolage SOAP interface are exported from
L<Template::Declare::TagSet::Bricolage|Template::Declare::TagSet::Bricolage>,
which you can use independent of this module if you require a bit more
control over the output.

But the advantage to using Template::Declare::Bricolage is that it sets up a
bunch of stuff for you, so that the usual infrastructure of setting up the
templating environment, outputting the top-level C<< <assets> >> element and
the XML namespace, is just handled. You can just focus on generating the XML
you need to send to Bricolage.

And the nice thing about Template::Declare's syntax is that it's, well,
I<declarative>. Just use the elements you need and it will do the rest. For
example, the code from the L<Synopsis|/"Synopsis"> returns:

    <assets xmlns="http://bricolage.sourceforge.net/assets.xsd">
      <workflow id="1027">
        <name>Blogs</name>
        <description>Blog Entries</description>
        <site>Main Site</site>
        <type>Story</type>
        <active>1</active>
        <desks>
          <desk start="1">Blog Edit</desk>
          <desk publish="1">Blog Publish</desk>
        </desks>
     </workflow>
   </assets>


=head2 C<bricolage {}>

In addition to all of the templating functions exported by
L<Template::Declare::TagSet::Bricolage|Template::Declare::TagSet::Bricolage>,
Template::Declare::Bricolage exports one more function, C<bricolage>. This is
the main function that you should use to generate your XML. It starts the XML
document with the XML declaration and the top-level C<< <assets> >> element
required by the the Bricolage SOAP API. Otherwise, it simply executes the
block passed to it. That block should simply use the formatting functions to
generate the XML you need for your assets. That's it.

=head1 Support

This module is stored in an open GitHub repository,
L<http://github.com/theory/template-declare-bricolage/tree/>. Feel free to
fork and contribute!

Please file bug reports at
L<http://github.com/theory/template-declare-bricolage/issues/>.

=head1 Author

=begin comment

Fake-out Module::Build. Delete if it ever changes to support =head1 headers
other than all uppercase.

=head1 AUTHOR

=end comment

=over

=item David E. Wheeler <david@kineticode.com>

=back

=head1 Copyright and License

Copyright (c) 2009 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

