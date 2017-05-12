package Parse::BBCode::Tag;
$Parse::BBCode::Tag::VERSION = '0.15';
use strict;
use warnings;
use Carp qw(croak carp);

use base 'Class::Accessor::Fast';
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw/ name attr attr_raw content
    finished start end close class single type in_url num level auto_closed /);

sub add_content {
    my ($self, $new) = @_;
    my $content = $self->get_content;
    if (ref $new) {
        push @$content, $new;
        return;
    }
    if (@$content and not ref $content->[-1]) {
        $content->[-1] .= $new;
    }
    else {
        push @$content, $new;
    }
}

sub raw_text {
    my ($self, %args) = @_;
    %args = (
        auto_close => 1,
        %args,
    );
    my $auto_close = $args{auto_close};
    my ($start, $end) = ($self->get_start, $self->get_end);
    if (not $auto_close and $self->get_auto_closed) {
        $end = '';
    }
    my $text = $start;
    $text .= $self->raw_content(%args);
    no warnings;
    $text .= $end;
    return $text;
}

sub _init_info {
    my ($self, $num, $level) = @_;
    $level ||= 0;
    my $name = $self->get_name;
    $num->{$name}++;
    $self->set_num($num->{$name});
    $self->set_level($level);
    my $content = $self->get_content || [];
    for my $c (@$content) {
        next unless ref $c;
        $c->_init_info($num, $level + 1);
    }
}

sub walk {
    my ($self, $type, $sub) = @_;
    $type ||= 'bfs';
    unless ($type eq 'bfs') {
        croak "walk(): $type '$type' not implemented";
    }
    my $result = $sub->($self);
    return if $result;
    my $content = $self->get_content || [];
    for my $c (@$content) {
        next unless ref $c;
        $c->walk($type, $sub);
    }
}

sub raw_content {
    my ($self, %args) = @_;
    my $content = $self->get_content;
    my $text = '';
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$self], ['self']);
    for my $c (@$content) {
        if (ref $c eq ref $self) {
            $text .= $c->raw_text(%args);
        }
        else {
            $text .= $c;
        }
    }
    return $text;
}

sub _reduce {
    my ($self) = @_;
    if ($self->get_finished) {
        return $self;
    }
    my @text = $self->get_start;
    my $content = $self->get_content;
    for my $c (@$content) {
        if (ref $c eq ref $self) {
            push @text, $c->_reduce;
        }
        else {
            push @text, $c;
        }
    }
    push @text, $self->get_end if defined $self->get_end;
    return @text;
}


1;

__END__

=pod

=head1 NAME

Parse::BBCode::Tag - Tag Class for Parse::BBCode

=head1 DESCRIPTION

If you parse a bbcode with L<Parse::BBCode> C<Parse::BBCode::parse> returns
a parse tree of Tag objects.

=head1 METHODS

=over 4

=item add_content

    $tag->add_content('string');

Adds 'string' to the end of the tag content.

    $tag->add_content($another_tag);

Adds C<$another_tag> to the end of the tag content.

=item raw_text

    my $bbcode = $tag->raw_text;

Returns the raw text of the parse tree, so all tags are converted
back to bbcode.

=item raw_content

    my $bbcode = $tag->raw_content;

Returns the raw content of the tag without the opening and closing tags.
So if you have tag that was parsed from

    [i]italic and [bold]test[/b][/i]

it will return

    italic and [bold]test[/b]

=item walk

Utility to do a breadth first search ('bfs') over the parsed tree.

    $tag->walk('bfs', sub {
            # tag is in $_
            ...
            return 0;
        });

When the sub returns 1 it stops walking the tree. Useful for
finding a certain tag.

=back

=head1 ACCESSORS

The accessors of a tag are currently

    name attr attr_raw content finished start end close class

You can call each accessor with C<get_*> and C<set_*>

=over 4

=item name

The tag name. for C<[i]...[/i]> it is C<i>, the lowercase tag name.

=item attr

TODO

=item attr_raw

The raw text of the attribute

=item content

An arrayref of the content of the tag, each element either a string
or a tag itself.

=item finished

Used during parsing, true if the end of the tag was found.

=item start

The original start string, e.g. 'C<[size=7]>'

=item end

The original end string, e.g. 'C<[/size]>'

=item close

True if the tag needs a closing tag. A tag which doesn't need a closing
tag is C<[*]> for example, inside of C<[list]> tags.

=item class

'block', 'inline' or 'url'

=item single

If this tag does not have a closing tag and also no content, like
[hr], for example, set this to true. Default is 0.

=item num

Absolute number of tag with this name in the tree. Useful if you want
to number code tags and offer download links.

=item level

Level of tag

For the tag [u] in the following bbcode

    [b]bold [i]italic [u]underlined[/u][/i][/b]

it returns 3.

=back

=cut


