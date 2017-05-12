package Template::Declare::TagSet::Bricolage;

use strict;
use base 'Template::Declare::TagSet';

sub get_tag_list {
    return [qw(
        action
        actions
        active
        adstring
        adstring2
        assets
        autopopulated
        bcc
        biz_class
        burner
        can_be_overridden
        can_copy
        can_preview
        can_publish
        categories
        category
        cc
        cols
        contact
        contacts
        container
        content_type
        contrib_type
        contributor
        contributors
        cookie
        cover_date
        data
        default
        default_val
        deploy_date
        deploy_status
        description
        desk
        desks
        dest
        displayed
        doc_root
        domain_name
        element_type
        element_type_set
        elements
        expire_date
        ext
        exts
        field
        field_type
        field_types
        file
        file_ext
        file_name
        filename
        first_publish_date
        fixed_uri
        fixed_uri_format
        fixed_url
        fname
        from
        handle_other
        handle_text
        host_name
        include
        includes
        is_media
        key_name
        keyword
        keywords
        length
        lname
        login
        manual
        max_occur
        max_size
        media
        media_type
        min_occur
        mname
        move_method
        multiple
        name
        opt
        opt_type
        options
        opts
        os
        output_channel
        output_channels
        paginated
        password
        path
        place
        post_path
        pre_path
        precision
        pref
        prefix
        primary_uri
        priority
        protocol
        publish
        publish_date
        publish_status
        related_media
        related_story
        repeatable
        required
        role
        rows
        screen_name
        server
        servers
        site
        sites
        size
        slug
        sort_name
        source
        story
        subelement_type
        subelement_types
        subject
        suffix
        template
        to
        top_level
        type
        uri
        uri_case
        uri_format
        use_slug
        user
        val_name
        value
        widget_type
        workflow
    )];
}

sub get_alternate_spelling {
    return 'tplate' if $_[1] eq 'template';
    return 'len'    if $_[1] eq 'length';
    return;
}

1;

__END__

=head1 Name

Template::Declare::TagSet::Bricolage - Tag set for Generating Bricolage SOAP XML

=head1 Synopsis

  package My::Bricolage::SOAP::Gen;
  use base 'Template::Declare';
  use Template::Declare::Tags 'Bricolage';

  template bricolage => sub {
      xml_decl { 'xml', version => '1.0', encoding => 'utf-8' };
      assets {
          attr { xmlns =>  'http://bricolage.sourceforge.net/assets.xsd' };
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
      }
  };

  package main;
  use Template::Declare;

  Template::Declare->init( roots => ['My::Bricolage::SOAP::Gen']);
  print Template::Declare->show('bricolage');

=head1 Description

This module creates a tag set to support all of the XML elements understood by
the Bricolage SOAP API. See L<Template::Declare|Template::Declare> and
L<Template::Declare::Tags|Template::Declare::Tags> for details on how to use
it. Better yet, use
L<Template::Declare::Bricolage|Template::Declare::Bricolage> and keep it
simple.

The exported tag functions are:

=over

=item * C<action>

=item * C<actions>

=item * C<active>

=item * C<adstring>

=item * C<adstring2>

=item * C<assets>

=item * C<autopopulated>

=item * C<bcc>

=item * C<biz_class>

=item * C<burner>

=item * C<can_be_overridden>

=item * C<can_copy>

=item * C<can_preview>

=item * C<can_publish>

=item * C<categories>

=item * C<category>

=item * C<cc>

=item * C<cols>

=item * C<contact>

=item * C<contacts>

=item * C<container>

=item * C<content_type>

=item * C<contrib_type>

=item * C<contributor>

=item * C<contributors>

=item * C<cookie>

=item * C<cover_date>

=item * C<data>

=item * C<default>

=item * C<default_val>

=item * C<deploy_date>

=item * C<deploy_status>

=item * C<description>

=item * C<desk>

=item * C<desks>

=item * C<dest>

=item * C<displayed>

=item * C<doc_root>

=item * C<domain_name>

=item * C<element_type>

=item * C<element_type_set>

=item * C<elements>

=item * C<expire_date>

=item * C<ext>

=item * C<exts>

=item * C<field>

=item * C<field_type>

=item * C<field_types>

=item * C<file>

=item * C<file_ext>

=item * C<file_name>

=item * C<filename>

=item * C<first_publish_date>

=item * C<fixed_uri>

=item * C<fixed_uri_format>

=item * C<fixed_url>

=item * C<fname>

=item * C<from>

=item * C<handle_other>

=item * C<handle_text>

=item * C<host_name>

=item * C<include>

=item * C<includes>

=item * C<is_media>

=item * C<key_name>

=item * C<keyword>

=item * C<keywords>

=item * C<len> (Alias for "length")

=item * C<lname>

=item * C<login>

=item * C<manual>

=item * C<max_occur>

=item * C<max_size>

=item * C<media>

=item * C<media_type>

=item * C<min_occur>

=item * C<mname>

=item * C<move_method>

=item * C<multiple>

=item * C<name>

=item * C<opt>

=item * C<opt_type>

=item * C<options>

=item * C<opts>

=item * C<os>

=item * C<output_channel>

=item * C<output_channels>

=item * C<paginated>

=item * C<password>

=item * C<path>

=item * C<place>

=item * C<post_path>

=item * C<pre_path>

=item * C<precision>

=item * C<pref>

=item * C<prefix>

=item * C<primary_uri>

=item * C<priority>

=item * C<protocol>

=item * C<publish>

=item * C<publish_date>

=item * C<publish_status>

=item * C<related_media>

=item * C<related_story>

=item * C<repeatable>

=item * C<required>

=item * C<role>

=item * C<rows>

=item * C<screen_name>

=item * C<server>

=item * C<servers>

=item * C<site>

=item * C<sites>

=item * C<size>

=item * C<slug>

=item * C<sort_name>

=item * C<source>

=item * C<story>

=item * C<subelement_type>

=item * C<subelement_types>

=item * C<subject>

=item * C<suffix>

=item * C<tplate> (Alias for "template")

=item * C<to>

=item * C<top_level>

=item * C<type>

=item * C<uri>

=item * C<uri_case>

=item * C<uri_format>

=item * C<use_slug>

=item * C<user>

=item * C<val_name>

=item * C<value>

=item * C<widget_type>

=item * C<workflow>

=back

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

