package Module::Build::Smolder;
use warnings;
use strict;
use base 'Module::Build::TAPArchive';
use WWW::Mechanize;
use Carp qw(croak);

our $VERSION = '0.02';
__PACKAGE__->add_property('server');
__PACKAGE__->add_property('username');
__PACKAGE__->add_property('password');
__PACKAGE__->add_property('project_id');
__PACKAGE__->add_property('architecture');
__PACKAGE__->add_property('platform');
__PACKAGE__->add_property('tags');
__PACKAGE__->add_property('comments');
__PACKAGE__->add_property('use_existing_archive');

=head1 NAME

Module::Build::Smolder - Extra build targets for sending smoke tests to a Smolder server

=head1 SYNOPSIS

Easily add support for extra build targets to send TAP Archives to a Smolder server

In your Build.PL

    use Module::Builder::Smolder;
    my $builder = Module::Builder::Smolder->new(
        ...
    );

Now you get these build targets

    ]$ perl Build.PL
    ]$ ./Build smolder ...

=head1 NEW TARGETS

The following build targets are provided:

=head2 smolder

Create a TAP archive and then send it to Smolder.

=head3 Required Flags

 This target needs to know where to send the archive, so it needs the following options:

=over

=item --server

=item --project_id

=back

    ]$ ./Build smolder --server mysmolder.com --username foo --password s3cr3t --project_id 5

=head3 Optional Flags

=over

=item --username

The Smolder user uploading the report. If not specified it will be uploaded anonymously

=item --password

=item --archive_file

Specify the file to store the archive

=item --architecture

Name of the architecture for the report

=item --platform

Name of the CPU platform

=item --tags

Comma separated list of tags for this report

=item --comments

Free form text to associate with the smoke report

=item --use_existing_archive

If you've already run the tests and created a TAP Archive and you just
want to submit that one to Smolder again, use this flag so that it doesn't
run the tests again. Really useful when troubleshooting.

=back

=cut

sub ACTION_smolder {
    my $self = shift;
    my $p = $self->{properties};

    # make sure we have the important options
    foreach my $opt qw(server project_id) {
        croak "Required option --$opt needs to be set" unless $p->{$opt};
    }

    # if we have --username then we need --password
    croak "You need to specify --password if you are giving a --username"
        if $p->{username} && !$p->{password};
    croak "You need to specify --username if you are giving a --password"
        if $p->{password} && !$p->{username};

    # make sure our archive_file is there and we can use it
    my $file = $p->{archive_file};
    if($file ) {
        if(!-e $file) {
            croak "Archive file $file does not exist!";
        } elsif(!-r $file) {
            croak "Archive file $file is not readable!";
        }
    } else {
        croak "No archive_file was created. Something is really wrong!";
    }

    $self->depends_on('code');
    $self->depends_on('test_archive') unless $p->{use_existing_archive};

    # try and reach the smolder server
    my $server = $p->{server};
    print "Trying to reach Smolder server at $server.\n";
    my $mech     = WWW::Mechanize->new();
    my $base_url = "http://$server/app";
    eval { $mech->get($base_url) };
    unless ($mech->status eq '200') {
        warn "Could not reach $server successfully. Received status " . $mech->status . "\n";
        exit(1);
    }

    # now login if we need to
    my $user = $p->{username};
    my $pw = $p->{password};
    my ($logged_in, $content);
    if( $user && $pw ) {
        print "Trying to login with username '$user'.\n";
        $mech->get($base_url . '/public_auth/login');
        my $form = $mech->form_name('login');
        if ($mech->status ne '200' || !$form) {
            warn "Could not reach Smolder login form. Are you sure $server is a Smolder server?\n";
            exit(1);
        }
        $mech->set_fields(
            username => $user,
            password => $pw,
        );
        $mech->submit();
        $content = $mech->content;
        if ($mech->status ne '200' || $content !~ /Welcome \Q$user\E/) {
            warn "Could not login with username '$user' and password '$pw'!\n";
            exit(1);
        }
        $logged_in = 1;
    }

    # now go to the add-smoke-report page for this project
    my $project_id = $p->{project_id};
    print "Adding smoke report to project #$project_id.\n";
    my $url = "$base_url/" . ($logged_in ? 'developer' : 'public') . "_projects/add_report/$project_id";
    $mech->get($url);
    $content = $mech->content;
    if ($mech->status ne '200' || $content !~ /New Smoke Report/) {
        if( $content =~ /unauthorized/i ) {
            warn "You are not authorized to submit reports to this project!\n";
        } elsif( $content =~ /not a public project/i ) {
            warn "This is not a public project. You need to specify --username!\n";
        } elsif( $content =~ /not allow anonymous/i ) {
            warn "This project does not allow anonymouse reports!\n";
        } else {
            warn "Could not reach the Add Smoke Report form!\n";
        }
        exit(1);
    }
    $mech->form_name('add_report');
    my %fields = (report_file => $file);
    $fields{platform}     = $p->{platform}     if ($p->{platform});
    $fields{architecture} = $p->{architecture} if ($p->{architecture});
    $fields{tags}         = $p->{tags}         if ($p->{tags});
    $fields{comments}     = $p->{comments}     if ($p->{comments});
    $mech->set_fields(%fields);
    $mech->submit();

    $content = $mech->content;
    if ($mech->status ne '200' || $content !~ /Recent Smoke Reports/) {
        warn "Could not upload smoke report with the given information!\n";
        exit(1);
    }
    if( $content =~ /#(\d+) Added/ ) {
        my $report_id = $1;
        print "Smoke Report successfully uploaded to Smolder server $server as #$report_id.\n";
    } else {
        print "Smoething strange happened. " . "We're not sure if the report was successfully uploaded or not.\n";
    }
}


=head1 AUTHOR

Michael Peters, C<< <mpeters at plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-build-taparchive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Build-Smolder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Build::Smolder

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Build-Smolder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Build-Smolder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Build-Smolder>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Build-Smolder/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Peters, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
