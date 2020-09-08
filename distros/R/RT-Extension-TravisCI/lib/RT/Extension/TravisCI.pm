use strict;
package RT::Extension::TravisCI;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-TravisCI - Pull status of latest build from TravisCI

=cut

require RT::Config;
use RT::Date;
use LWP::UserAgent ();
use URI::Escape;
use JSON;

$RT::Config::META{TravisCI} = {
    Type => 'HASH',
};

RT->AddStyleSheets('travisci.css');
RT->AddJavaScript('travisci.js');

sub getconf
{
    my $thing = shift;
    return RT->Config->Get('TravisCI')->{$thing};
}

sub parse_subject_for_project_and_branch
{
    my $subject = shift;

    # Trim leading and trailing whitespace from subject
    $subject =~ s/^\s+//;
    $subject =~ s/\s+$//;

    if ($subject =~ /^([A-Za-z_.-]+)[\/ ](.+)/) {
        RT->Logger->debug(
            "Extracted project '$1' and branch '$2' from ticket subject '$subject'");
        return ($1, $2);
    } else {
        my $proj = getconf('DefaultProject') // 'rt';
        RT->Logger->debug("Using ticket subject as branch '$subject' in project $proj");
        return ($proj, $subject);
    }
}

sub pretty_state {
    my $state = shift;
    return "Passed" if ($state eq 'passed');
    return "Failed" if ($state eq 'failed');
    return "Errored" if ($state eq 'errored');
    return $state;
}

sub format_date
{
    my ($date_iso8601, $current_user) = @_;

    # Remove the trailing 'Z' we get back from Travis CI;
    # RT::Date will not parse the date if it is present.  We also
    # need to change the 'T' to a space or it will fail to parse.
    $date_iso8601 =~ s/Z$//;
    $date_iso8601 =~ s/T/ /;

    my $d = RT::Date->new($current_user);
    if ($d->Set(Value => $date_iso8601, Format => 'ISO')) {
        return $d->AsString;
    }
    return $date_iso8601;
}

sub get_status
{
    my $proj = shift;
    my $branch = shift;
    my $current_user = shift;

    my $ua = LWP::UserAgent->new();

    my $slug = getconf('SlugPrefix');
    # Add the escaped / '%2F' if slug doesn't already end in it
    $slug .= '%2F' unless $slug =~ /%2f$/i;

    my $url = getconf('APIURL') . '/repo/' . $slug . uri_escape($proj) . '/branch/' . uri_escape($branch);
    my $response = $ua->get($url,
                            'Travis-API-Version' => getconf('APIVersion'),
                            'Authorization' => 'token ' . getconf('AuthToken'),
        );

    if (!$response->is_success) {
        return { success => 0, error => $response->status_line };
    }

    my $result;
    eval {
        $result = decode_json($response->decoded_content);
    };
    if ($@) {
        return { success => 0, error => 'Could not parse result as JSON' };
    }

    if ( !$result->{last_build} ) {
        return { success => 0, error => 'Not found' };
    }

    # Format the dates according to user preference
    $result->{last_build}->{started_at}  = format_date($result->{last_build}->{started_at}, $current_user);
    $result->{last_build}->{finished_at} = format_date($result->{last_build}->{finished_at}, $current_user);

    return { success => 1, result => $result };
}

1;

__END__

=head1 DESCRIPTION

This extension provides a portlet showing the TravisCI build results
for the latest build on a branch.

=head1 RT VERSION

Works with RT 5.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt5/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::TravisCI');

=item Edit your F</opt/rt5/etc/RT_SiteConfig.d/TravisCI_Config.pm> (creating
it if necessary) using the included F<etc/TravisCI_Config.pm> as a guide.

=over

The settings you are most likely to want to change are F<SlugPrefix>,
which should be your organization's identifier; DefaultProject, Queues
and AuthToken.

You will need to generate an authentication token as documented in
https://medium.com/@JoshuaTheMiller/retrieving-your-travis-ci-api-access-token-bc706b2b625a

=back

=item Clear your mason cache

    rm -rf /opt/rt5/var/mason_data/obj

=item Restart your webserver

=back

=head1 DETERMINING THE PROJECT AND BRANCH

To determine the project and branch names, the extension parses the
Subject of the ticket.  If the subject matches:

    /^([A-Za-z_.-]+)[\/ ](.+)/

then the first submatch is taken to be the project name and the second to
be the branch name.  Otherwise, the project name is taken to be the
DefaultProject configuration variable in TravisCI_Config.pm, and the
branch name is taken to be the entire ticket subject.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-TravisCI@rt.cpan.org">bug-RT-Extension-TravisCI@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TravisCI">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-TravisCI@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-TravisCI

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Best Practical Solutions, LLC

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
