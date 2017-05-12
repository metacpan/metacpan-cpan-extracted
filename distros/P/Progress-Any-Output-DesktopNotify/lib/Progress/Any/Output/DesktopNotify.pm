package Progress::Any::Output::DesktopNotify;

our $DATE = '2014-10-14'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Desktop::Notify;
my $notify = Desktop::Notify->new;

sub new {
    my ($class, %args0) = @_;

    my %args;

    for ('summary_template') {
        $args{$_} = delete($args0{$_});
        $args{$_} //= '%t';
    }
    for ('body_template') {
        $args{$_} = delete($args0{$_});
        $args{$_} //= '%m %p%% %R';
    }

    keys(%args0) and die "Unknown output parameter(s): ".
        join(", ", keys(%args0));

    bless \%args, $class;
}

sub update {
    my ($self, %args) = @_;

    my $p = $args{indicator};

    # create notification object if not already exists
    $p->{__DesktopNotify_obj} //= $notify->create(
        summary => $p->fill_template($self->{summary_template}, %$p, %args),
        body    => '',
        timeout => 5000, # XXX configurable
    );

    my $n = $p->{__DesktopNotify_obj};

    $n->body($p->fill_template($self->{body_template}, %args));
    $n->show;
}

sub cleanup {
    my ($self) = @_;

    for (values %Progress::Any::indicators) {
        my $n = $_->{__DesktopNotify_obj};
        $n->close if $n;
    }
}

1;
# ABSTRACT: Output progress to Desktop::Notify

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::DesktopNotify - Output progress to Desktop::Notify

=head1 VERSION

This document describes version 0.02 of Progress::Any::Output::DesktopNotify (from Perl distribution Progress-Any-Output-DesktopNotify), released on 2014-10-14.

=head1 SYNOPSIS

 use Progress::Any::Output;
 Progress::Any::Output->set('DesktopNotify',
     summary_template=>'%t',
     body_template=>'%m %p%% %R',
 );

An example program:

 use Progress::Any;
 use Progress::Any::Output;

 Progress::Any::Output->set({task=>'t1'}, 'DesktopNotify');
 Progress::Any::Output->set({task=>'t2'}, 'DesktopNotify');

 my $p1 = Progress::Any->get_indicator(task=>'t1', title=>'Copying ...', target=>10);
 my $p2 = Progress::Any->get_indicator(task=>'t1', title=>'Verifying ...', target=>10);
 for (1..15) {
     $p1->update(message => "File $_") if $_ <= 10;
     $p2->update(message => "File ".($_-5)) if $_ > 5;
     sleep 1;
 }

=head1 DESCRIPTION

This output sends progress updates to Desktop::Notify. Each task will get its
own notification object.

Sample output (on Linux with XFCE):

=for Pod::Coverage ^(update|cleanup)$

=for HTML <img src="http://blogs.perl.org/users/perlancar/progany-dn-sample.jpg" />

=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("DesktopNotify", %args) >>.

Known arguments:

=over

=item * summary_template => str (default: '%t')

When creating notification, use this template. Will be passed to
C<Progress::Any>'s C<fill_template()> routine.

=item * body_template => str (default: '%m %p %R')

When updating notification body, use this template. Will be passed to
C<Progress::Any>'s C<fill_template()> routine.

=back

=head1 ENVIRONMENT

=head1 TODO

=head1 SEE ALSO

L<Progress::Any>

L<Desktop::Notify>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any-Output-DesktopNotify>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Progress-Any-Output-DesktopNotify>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any-Output-DesktopNotify>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
