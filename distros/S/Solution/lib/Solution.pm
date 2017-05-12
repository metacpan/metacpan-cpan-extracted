package Solution;
{
    use strict;
    use warnings;
    our $VERSION = '0.9.1';
    use Solution::Document;
    use Solution::Context;
    use Solution::Tag;
    use Solution::Block;
    use Solution::Condition;
    use Solution::Template;

    #
    {    # Load all the tags from the standard library
        require File::Find;
        require File::Spec;
        require File::Basename;
        use lib '../';
        for my $type (qw[Tag Filter]) {
            File::Find::find(
                {wanted => sub {
                     require $_ if m[(.+)\.pm$];
                 },
                 no_chdir => 1
                },
                File::Spec->rel2abs(
                      File::Basename::dirname(__FILE__) . '/Solution/' . $type
                )
            );
        }
    }
    my (%tags, @filters);
    sub register_tag { $tags{$_[1]} = $_[2] ? $_[2] : scalar caller }
    sub tags { return \%tags }
    sub register_filter { push @filters, $_[1] ? $_[1] : scalar caller }
    sub filters { return \@filters }
}
1;

=pod

=head1 NAME

Solution - A Simple, Stateless Template System

=head1 Synopsis

    use Solution;
    my $template = Solution::Template->new();
    $template->parse(    # See Solution::Tag for more examples
          '{% for x in (1..3) reversed %}{{ x }}, {% endfor %}{{ some.text }}'
    );
    print $template->render({some => {text => 'Contact!'}}); # 3, 2, 1, Contact!

=head1 Description

L<Solution|/"'Solution to what?' or 'Ugh! Why a new Top Level Namespace?'"> is
a template engine based on Liquid. The Liquid template engine was crafted for
very specific requirements:

=over 4

=item * It has to have simple markup and beautiful results. Template engines
which don't produce good looking results are no fun to use.

=item * It needs to be non-evaling and secure. Liquid templates are made so
that users can edit them. You don't want to run code on your server which your
users wrote.

=item * It has to be stateless. The compile and render steps have to be
separate, so that the expensive parsing and compiling can be done once; later
on, you can just render it by passing in a hash with local variables and
objects.

=item * It needs to be able to style emails as well as HTML.

=back

=head1 Getting Started

It's very simple to get started with L<Solution|Solution>. Just as in Liquid,
templates are built and used in two steps: Parse and Render.

    my $sol = Solution::Template->new();  # Create a Solution::Template object
    $sol->parse('Hi, {{name}}!');         # Parse and compile the template
    $sol->render({name => 'Sanko'});      # Render the output => "Hi, Sanko!"

    # Or if you're in a hurry...
    Solution::Template->parse('Hi, {{name}}!')->render({name => 'Sanko'});

The C<parse> step creates a fully compiled template which can be re-used as
often as you like. You can store it in memory or in a cache for faster
rendering later.

All parameters you want Solution to work with have to be passed as parameters
to the C<render> method. Solution is a closed ecosystem; it does not know
about your local, instance, global, or environment variables.

For an expanded overview of the Liquid/Solution syntax, please see
L<Solution::Tag> and read
L<Liquid for Designers|http://wiki.github.com/tobi/liquid/liquid-for-designers>.

=head1 Extending Solution

Extending the Solution template engine for your needs is almost too simple.
Keep reading.

=head2 Custom Filters

Filters are simple subs called when needed. They are not passed any state data
by design and must return the modified content.

TODO: I need to write Solution::Filter which will be POD with all sorts of
info in it. Yeah.

=head3 C<< Solution->register_filter( ... ) >>

This registers a package which Solution will assume contains one or more
filters.

    # Register a package as a filter
    Solution->register_filter( 'SolutionX::Filter::Amalgamut' );

    # Or simply say...
    Solution->register_filter( );
    # ...and Solution will assume the filters are in the calling package

=head3 C<< Solution->filters( ) >>

Returns a list containing all the tags currently loaded for informational
purposes.

=head2 Custom Tags

See the section entitled
L<Extending Solution with Custom Tags|Solution::Tag/"Extending Solution with Custom Tags">
in L<Solution::Tag> for more information.

To assist with custom tag creation, Solution provides several basic tag types
for subclassing and exposes the following methods:

=head3 C<< Solution->register_tag( ... ) >>

This registers a package which must contain (directly or through inheritance)
both a C<parse> and C<render> method.

    # Register a new tag which Solution will look for in the given package
    Solution->register_tag( 'newtag', 'SolutionX::Tag::You're::It' );

    # Or simply say...
    Solution->register_tag( 'newtag' );
    # ...and Solution will assume the new tag is in the calling package

Pre-existing tags are replaced when new tags are registered with the same
name. You may want to do this to override some functionality.

=head3 C<< Solution->tags( ) >>

Returns a hashref containing all the tags currently loaded for informational
purposes.

=head1 Why should I use Solution?

=over 4

=item * You want to allow your users to edit the appearance of your
application, but don't want them to run insecure code on your server.

=item * You want to render templates directly from the database.

=item * You like Smarty-style template engines.

=item * You need a template engine which does HTML just as well as email.

=item * You don't like the markup language of your current template engine.

=item * You wasted three days reinventing this wheel when you could have been
doing something productive like volunteering or catching up on past seasons of
I<Doctor Who>.

=back

=head1 Why shouldn't I use Solution?

=over 4

=item * You've found or written a template engine which fills your needs
better than Liquid or Solution ever could.

=item * You are uncomfortable with text that you didn't copy and paste
yourself. Everyone knows computers cannot be trusted.

=back

=head1 'Solution to what?' or 'Ugh! Why a new Top Level Namespace?'

I really don't have a good reason for claiming a new top level namespace and I
promise to put myself in timeout as punishment.

As I understand it, the original project's name, Liquid, is a reference to the
classical states of matter (the engine itself being stateless). I settled on
L<Solution|http://en.wikipedia.org/wiki/Solution> because it's Liquid but...
with... bits of other stuff floating in it. (Pretend you majored in chemistry
instead of mathematics or computer science.) Liquid tempates will I<always> be
work with Solution but (due to Solution's expanded syntax) Solution templates
I<may not> be compatible with Liquid.

This 'solution' is B<not> the answer to all your problems and obviously not
the only solution for your templating troubles. It's simply I<a> solution.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=encoding utf8

The original Liquid template system was developed by
L<jadedPixel|http://jadedpixel.com/> and
L<Tobias Lütke|http://blog.leetsoft.com/>.

=head1 License and Legal

Copyright (C) 2009,2010 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of
L<The Artistic License 2.0|http://www.perlfoundation.org/artistic_license_2_0>.
See the F<LICENSE> file included with this distribution or
L<notes on the Artistic License 2.0|http://www.perlfoundation.org/artistic_2_0_notes>
for clarification.

When separated from the distribution, all original POD documentation is
covered by the
L<Creative Commons Attribution-Share Alike 3.0 License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>.
See the
L<clarification of the CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
{
    { package Solution::Drop;           our $VERSION = '0.9.1'; }
    { package Solution::Extensions;     our $VERSION = '0.9.1'; }
    { package Solution::HTMLTags;       our $VERSION = '0.9.1'; }
    { package Solution::Module_Ex;      our $VERSION = '0.9.1'; }
    { package Solution::Strainer;       our $VERSION = '0.9.1'; }
    { package Solution::Tag::IfChanged; our $VERSION = '0.9.1'; }

    #
    { package Liquid;                   our $VERSION = '0.9.1' }
    { package Liquid::Variable;         our $VERSION = '0.9.1' }
    { package Liquid::Utility;          our $VERSION = '0.9.1' }
    { package Liquid::Template;         our $VERSION = '0.9.1' }
    { package Liquid::Tag;              our $VERSION = '0.9.1' }
    { package Liquid::Tag::Unless;      our $VERSION = '0.9.1' }
    { package Liquid::Tag::Raw;         our $VERSION = '0.9.1' }
    { package Liquid::Tag::Include;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::IfChanged;   our $VERSION = '0.9.1' }
    { package Liquid::Tag::If;          our $VERSION = '0.9.1' }
    { package Liquid::Tag::For;         our $VERSION = '0.9.1' }
    { package Liquid::Tag::Cycle;       our $VERSION = '0.9.1' }
    { package Liquid::Tag::Comment;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::Case;        our $VERSION = '0.9.1' }
    { package Liquid::Tag::Capture;     our $VERSION = '0.9.1' }
    { package Liquid::Tag::Assign;      our $VERSION = '0.9.1' }
    { package Liquid::SyntaxError;      our $VERSION = '0.9.1' }
    { package Liquid::Strainer;         our $VERSION = '0.9.1' }
    { package Liquid::StandardError;    our $VERSION = '0.9.1' }
    { package Liquid::StackLevelError;  our $VERSION = '0.9.1' }
    { package Liquid::Module_Ex;        our $VERSION = '0.9.1' }
    { package Liquid::HTMLTags;         our $VERSION = '0.9.1' }
    { package Liquid::FilterNotFound;   our $VERSION = '0.9.1' }
    { package Liquid::Filter::Standard; our $VERSION = '0.9.1' }
    { package Liquid::FileSystemError;  our $VERSION = '0.9.1' }
    { package Liquid::Extensions;       our $VERSION = '0.9.1' }
    { package Liquid::Error;            our $VERSION = '0.9.1' }
    { package Liquid::Drop;             our $VERSION = '0.9.1' }
    { package Liquid::Document;         our $VERSION = '0.9.1' }
    { package Liquid::ContextError;     our $VERSION = '0.9.1' }
    { package Liquid::Context;          our $VERSION = '0.9.1' }
    { package Liquid::Condition;        our $VERSION = '0.9.1' }
    { package Liquid::Block;            our $VERSION = '0.9.1' }
    { package Liquid::ArgumentError;    our $VERSION = '0.9.1' }
}
1;
__END__
Module                            Purpose/Notes              Inheritance
-----------------------------------------------------------------------------------------------------------------------------------------
Solution                          | [done]                    |
    Solution::Block               |                           |
    Solution::Condition           | [done]                    |
    Solution::Context             | [done]                    |
    Solution::Document            | [done]                    |
    Solution::Drop                |                           |
    Solution::Errors              | [done]                    |
    Solution::Extensions          |                           |
    Solution::FileSystem          |                           |
    Solution::HTMLTags            |                           |
    Solution::Module_Ex           |                           |
    Solution::StandardFilters     | [done]                    |
    Solution::Strainer            |                           |
    Solution::Tag                 |                           |
        Solution::Tag::Assign     | [done]                    | Solution::Tag
        Solution::Tag::Capture    | [done] extended assign    | Solution::Tag
        Solution::Tag::Case       |                           |
        Solution::Tag::Comment    | [done]                    | Solution::Tag
        Solution::Tag::Cycle      |                           |
        Solution::Tag::For        | [done] for loop construct | Solution::Tag
        Solution::Tag::If         | [done] if/elsif/else      | Solution::Tag
        Solution::Tag::IfChanged  |                           |
        Solution::Tag::Include    | [done]                    | Solution::Tag
        Solution::Tag::Unless     | [done]                    | Solution::Tag::If
    Solution::Template            |                           |
    Solution::Variable            | [done] echo statement     | Solution::Document
Solution::Utility       *         | [temp] Non OO bin         |
