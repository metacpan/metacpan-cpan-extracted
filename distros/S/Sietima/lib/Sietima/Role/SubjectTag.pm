package Sietima::Role::SubjectTag;
use Moo::Role;
use Sietima::Policy;
use Types::Standard qw(Str);
use namespace::clean;

our $VERSION = '1.0.2'; # VERSION
# ABSTRACT: add a tag to messages' subjects


has subject_tag => (
    is => 'ro',
    isa => Str,
    required => 1,
);


around munge_mail => sub ($orig,$self,$mail) {
    my $tag = '['.$self->subject_tag.']';
    my $subject = $mail->header_str('Subject');
    unless ($subject =~ m{\Q$tag\E}) {
        $mail->header_str_set(
            Subject => "$tag $subject",
        );
    }
    return $self->$orig($mail);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sietima::Role::SubjectTag - add a tag to messages' subjects

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

  my $sietima = Sietima->with_traits('SubjectTag')->new({
    %args,
    subject_tag => 'foo',
  });

=head1 DESCRIPTION

A L<< C<Sietima> >> list with this role applied will prepend the given
tag to every outgoing message's C<Subject:> header.

=head1 ATTRIBUTES

=head2 C<subject_tag>

Required string. This string, enclosed by square brackets, will be
prepended to the C<Subject:> header of outgoing messages. For example,
the code in the L</synopsis> would cause an incoming message with
subject "new stuff" to be sent out with subject "[foo] new stuff".

If the incoming message's C<Subject:> header already contains the tag,
the header will not be modified. This prevents getting subjects like
"[foo] Re: [foo] Re: [foo] new stuff".

=head1 MODIFIED METHODS

=head2 C<munge_mail>

The subject of the incoming email is modified to add the tag (unless
it's already there). The email is then processed normally.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
