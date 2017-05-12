package Net::Lyskom::Info;
use base qw{Net::Lyskom::Object};

use strict;
use warnings;

use Net::Lyskom::AuxItem;
use Net::Lyskom::Util qw{:all};

=head1 NAME

Net::Lyskom::Info - server information object.

=head1 SYNOPSIS

  print "Conference presentations can be found in conference number ",$obj->conf_pres_conf;

=head1 DESCRIPTION

=over

=item ->version()

Server version-

=item ->conf_pres_conf()

Conference with conference presentations.

=item ->pers_pres_conf()

Conference with person presentations.

=item ->motd_conf()

Message of the Day conference.

=item ->kom_news_conf()

Conference where news about the server is posted.

=item ->motd_of_lyskom()

Text with MOTD for the server.

=item ->aux_item_list()

Returns a list of L<Net::Lyskom::AuxInfo> objects.

=back

=cut

sub new_from_stream {
    my $s = {};
    my $class = shift;
    my $ref = shift;

    $class = ref($class) if ref($class);
    bless $s, $class;

    $s->{version} = shift @{$ref};
    $s->{conf_pres_conf} = shift @{$ref};
    $s->{pers_pres_conf} = shift @{$ref};
    $s->{motd_conf} = shift @{$ref};
    $s->{kom_news_conf} = @{$ref};
    $s->{motd_of_lyskom} = @{$ref};
    $s->{aux_item_list} = [parse_array_stream(sub{Net::Lyskom::AuxInfo->new_from_stream(@_)},$ref)];

    return $s;
}

sub version {my $s = shift; return $s->{version}}
sub conf_pres_conf {my $s = shift; return $s->{conf_pres_conf}}
sub pers_pres_conf {my $s = shift; return $s->{pers_pres_conf}}
sub motd_conf {my $s = shift; return $s->{motd_conf}}
sub kom_news_conf {my $s = shift; return $s->{kom_news_conf}}
sub motd_of_lyskom {my $s = shift; return $s->{motd_of_lyskom}}
sub aux_item_list {my $s = shift; return @{$s->{aux_item_list}}}

1;
