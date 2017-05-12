package Net::Lyskom::TextStat;
use base qw{Net::Lyskom::Object};
use strict;
use warnings;

use Net::Lyskom::Util qw{:all};
use Net::Lyskom::MiscInfo;
use Net::Lyskom::AuxItem;
use Carp;
use Encode;

=head1 NAME

Net::Lyskom::TextStat - text information object.

=head1 SYNOPSIS

  print localtime($obj->creation_time);

  print "This text has the subject: ",$obj->subject,"\n";


=head1 DESCRIPTION

Object returned by the get_text_stat method in the main L<Net::Lyskom>
class. Also fronts for get_text(), since one often wants the text mass
after getting the text meta-information.

=head2 Methods

=over

=item ->creation_time()

Returns the creation time as a L<Net::Lyskom::Time> object.

=item ->author()

Returns the person number of the author.

=item ->no_of_lines()

Returns the number of lines.

=item ->no_of_chars()

Returns the number of characters.

=item ->no_of_marks()

Returns the number of marks.

=item ->misc_info()

Returns a compacted list of L<Net::Lyskom::MiscInfo> object. See the
documentation for the class for the meaning of "compacted".

=item ->aux_items()

Returns a list of L<Net::Lyskom::AuxInfo> objects.

=item ->subject()

Returns the subject line of the text. Calls get_text(), and caches
both the subject and body internally. Both this method and the
following one always fetch the entire text. If you want something
else, call get_text() yourself.

If the fetched text has a content-type AuxItem, and the running Perl
instance knows how to convert from that encoding, the subject will be
decoded into Perl's internal representation before being returned. If
there is no declared content type or the running Perl can't deal with
it, the content will be left untouched.

=item ->body()

As above, but return the body instead of the subject.

=back

=cut

# Acessors

sub creation_time {
    my $s = shift;

    return $s->{creation_time};
}

sub author {
    my $s = shift;

    return $s->{author};
}

sub no_of_lines {
    my $s =shift;

    return $s->{no_of_lines};
}

sub no_of_chars {
    my $s = shift;

    return $s->{no_of_chars};
}

sub no_of_marks {
    my $s = shift;

    return $s->{no_of_marks};
}

sub misc_info {
    my $s =shift;

    return @{$s->{misc_info}};
}

sub aux_items {
    my $s =shift;

    return @{$s->{aux_item}};
}

sub _fetch_subject_and_body {
    my $s = shift;

    my $raw = $s->{connection}->get_text(text => $s->{textno}) or croak;

    my ($ct) = grep {$_->tag == 1} $s->aux_items;
    if ($ct) {
        my ($charset) = $ct->data =~ m|charset=([^;]+);?|i;
        if ($charset) {
            eval {
                $raw = decode($charset, $raw);
            };
        }
    }

    my ($subj, $body) = split(/\n/, $raw, 2);
    $s->{subject} = $subj;
    $s->{body} = $body;
}

sub subject {
    my $s = shift;

    return $s->{subject} if exists($s->{subject});
    return undef unless $s->{connection} && $s->{textno};

    $s->_fetch_subject_and_body();

    return $s->{subject};
}

sub body {
    my $s = shift;

    return $s->{body} if exists($s->{body});
    return undef unless $s->{connection} && $s->{textno};

    $s->_fetch_subject_and_body();

    return $s->{body};
}

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $conn = shift;
    my $textno = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s,$class;

    $s->{creation_time} = Net::Lyskom::Time->new_from_stream($ref);
    $s->{author} = shift @{$ref};
    $s->{no_of_lines} = shift @{$ref};
    $s->{no_of_chars} = shift @{$ref};
    $s->{no_of_marks} = shift @{$ref};
    $s->{misc_info} = [Net::Lyskom::MiscInfo->compact(parse_array_stream(sub{Net::Lyskom::MiscInfo->new_from_stream(@_)},$ref))];
    $s->{aux_item} = [parse_array_stream(sub{Net::Lyskom::AuxItem->new_from_stream(@_)},$ref)];

    $s->{connection} = $conn;
    $s->{textno} = $textno;
    return $s;
}

return 1;
