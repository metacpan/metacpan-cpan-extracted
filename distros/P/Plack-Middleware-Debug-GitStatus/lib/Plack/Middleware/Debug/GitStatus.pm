package Plack::Middleware::Debug::GitStatus;
use strict;
use warnings;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

use Plack::Util::Accessor qw( git_dir gitweb_url );
use Encode qw/ decode_utf8 encode_utf8 /;

use parent 'Plack::Middleware::Debug::Base';

sub run {
    my ( $self, undef, $panel ) = @_;

    return sub {
        my ( $branch, $info ) = $self->get_git_info;
        $panel->title( 'GitStatus' );
        $panel->nav_title( 'GitStatus' );
        $panel->nav_subtitle( 'On branch ' . $branch );
        $panel->content( $self->render_info( $info ) );
    }
}

sub render_info {
    my $self = shift;
    my $info = shift;

    my $html = qq|<table><thead><tr><th colspan="2">|;

    if ( $info->{ error } ) {
        $html .= qq|Error</th></tr></thead><tbody>
            <tr><td>Git reported an error</td><td>$info->{ error }</td></tr>
        |;
    }
    else {
        $html .= qq|Git status information</th></tr></thead><tbody>
            <tr><td>Current Branch</td><td><pre>$info->{ current_branch }</pre></td></tr>
            <tr><td>Status</td><td><pre>$info->{ status }</pre></td></tr>
            <tr><th>Last commit</th><th></th></tr>
            <tr><td>Date</td><td>$info->{ date }</td></tr>
            <tr><td>Author</td><td>$info->{ author }</td></tr>
            <tr><td>SHA-1</td><td>$info->{ sha_1 }</td></tr>
            <tr><td>Message</td><td>$info->{ message }</td></tr>
        |;

        if ( my $url = $self->gitweb_url ) {
            $html .= sprintf qq|<tr><td><a style="color: blue" href="$url" target="_blank">View</a></td><td></td></tr>\n|, $info->{ sha_1 };
        }
    }

    $html .= '</tbody></table>';

    return encode_utf8 $html;
}

sub get_git_info {
    my $self = shift;

    my ( $branch, $info ) = eval {
        if ( my $dir = $self->git_dir ) {
            if ( ! chdir $dir ) {
                die "Could not change to directory '$dir': $!";
            }
        }

        my $current_branch = `git symbolic-ref HEAD 2>&1`;

        if ( $? ) {
            die  "Git reported an error: $current_branch";
        }

        $current_branch =~ s|refs/heads/||;
        my %info = ( current_branch => $current_branch );
        $info{ status } = $self->get_git_status;

        my @ci_info = split /\0/, `git log -1 --pretty=format:%H%x00%an%x00%aD%x00%s`;
        $info{ sha_1 }   = shift @ci_info;
        $info{ author }  = decode_utf8 shift @ci_info;
        $info{ date }    = shift @ci_info;
        $info{ message } = decode_utf8 shift @ci_info;

        return $current_branch, \%info;
    };

    if ( my $err = $@ ) {
        return 'unknown', { error => $err };
    }
    else {
        return $branch, $info;
    }
}

sub get_git_status {
    my $self = shift;

    my $status = `git status -s`;
    return 'clean' unless $status;

    return $status;
}

1;

__END__

=head1 NAME

Plack::Middleware::Debug::GitStatus - Display git status information about the directory from which you run your development server

=head1 SYNOPSIS

 # Assuming your current directory is the relevant git dir:
 builder {
     enable 'Debug', panels => [ qw( Environment Response GitStatus ) ];
     $app;
 };

 # If you need to set a git dir:
 return builder {
     enable 'Debug', panels => [ qw( Environment Response ) ];
     enable 'Debug::GitStatus', git_dir => '/some/path';
     $app;
 };

 # or if you want to specify a url to gitweb/gitalist/etc:
 return builder {
     enable 'Debug', panels => [ qw( Environment Response ) ];
     enable 'Debug::GitStatus', gitweb_url => 'http://example.com/cgi-bin/gitweb?p=my_repo.git;h=%s';
     $app;
 };
 

=head1 DESCRIPTION

This panel gives you quick access to the most relevant git information:

=over

=item the currently checked out branch

=item git status information

=item information about the most recent commit

=back

=head1 CONFIGURATION

There are two optional parameters you can use to configure this panel plugin:

=over

=item git_dir

The path to your repository in case the current dir of your application is
outside of this.

=item gitweb_url

If you want the panel to give you a link to your gitweb, gitolite, etc installation,
provide the URL here. You need to provide a string that will be used as a format
string in a call to sprintf, thus the string needs to contain a %s which will be
supplied with the sha-1 of the most recent commit.

Example: 'http://localhost/somegitwebtool?hash=%s'

=back

=head1 SEE ALSO

L<https://metacpan.org/pod/Plack::Middleware::GitStatus> - Gives you the option to
send a HTTP request to your server that will be answered with git status information.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<https://github.com/mannih/Plack-Middleware-Debug-GitStatus>.

=head1 AUTHOR

Manni Heumann, C<< <cpan@lxxi.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Manni Heumann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

