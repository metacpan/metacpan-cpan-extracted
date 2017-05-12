# ============================================================================
package MooseX::App::Plugin::Version::Command;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose;
use MooseX::App::Command;

command_short_description q(Print the current version);

sub version {
    my ($self,$app) = @_;

    my $version = '';
    $version .= $app->meta->app_base. ' version '.$app->VERSION."\n";
    $version .= "MooseX::App version ".$MooseX::App::VERSION."\n";
    $version .= "Perl version ".sprintf("%vd", $^V);

    my $message_class = $app->meta->app_messageclass;

    my @parts = ($message_class->new({
        header  => 'VERSION',
        body    => MooseX::App::Utils::format_text($version)
    }));

    my %pod_raw = MooseX::App::Utils::parse_pod($app->meta->name);

    foreach my $part ('COPYRIGHT','LICENSE','COPYRIGHT AND LICENSE','AUTHOR','AUTHORS') {
        if (defined $pod_raw{$part}) {
            push(@parts,$message_class->new({
                header  => $part,
                body    => MooseX::App::Utils::format_text($pod_raw{$part}),
            }));
        }
    }

    return MooseX::App::Message::Envelope->new(@parts);
}

__PACKAGE__->meta->make_immutable;
1;