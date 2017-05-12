package Solution::Template;
{
    use strict;
    use warnings;
    use lib '..';
    our $VERSION = '0.9.1';
    use Solution::Utility;

    #
    sub context  { $_[0]->{'context'} }
    sub filters  { $_[0]->{'filters'} }
    sub tags     { $_[0]->{'tags'} }
    sub document { $_[0]->{'document'} }
    sub parent   { $_[0]->{'parent'} }
    sub resolve  { $_[0]->{'context'}->resolve($_[1], $_[2]) }

    #
    sub new {
        my ($class) = @_;
        my $self = bless {tags    => Solution->tags(),      # Global list
                          filters => Solution->filters()    # Global list
        }, $class;
        return $self;
    }

    sub parse {
        my ($class, $source) = @_;
        my $self = ref $class ? $class : $class->new();
        my @tokens = Solution::Utility::tokenize($source);
        $self->{'document'} ||= Solution::Document->new({template => $self});
        $self->{'document'}->parse(\@tokens);
        return $self;
    }

    sub render {
        my ($self, $assigns, $info) = @_;
        $info ||= {};
        $info->{'template'} = $self;
        $self->{'context'} = Solution::Context->new($assigns, $info);
        return $self->document->render();
    }

    sub register_filter {
        my ($self, $name) = @_;
        eval qq[require $name;];
        return push @{$self->{'filters'}}, $name;
    }

    sub register_tag {
        my ($self, $tag_name, $package) = @_;
        eval qq[require $package;];
        return $self->{'tags'}{$tag_name} = $package;
    }
}
1;

=pod

=head1 NAME

Solution::Template - Base class for all templates and template-like things

=head1 Description

This is used internally.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Solution|Solution/"Create your own filters">'s docs on custom filter creation

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
