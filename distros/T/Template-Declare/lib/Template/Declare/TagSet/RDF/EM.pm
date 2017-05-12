package Template::Declare::TagSet::RDF::EM;

use strict;
use warnings;
use base 'Template::Declare::TagSet';
#use Smart::Comments;

sub get_tag_list {
    return [ qw{
        aboutURL    contributor    creator
        description    developer    file
        hidden    homepageURL    iconURL
        id    locale    localized
        maxVersion    minVersion    name
        optionsURL    package    requires
        skin    targetApplication    targetPlatform
        translator    type    updateURL
        version
    } ];
}

1;
__END__

=head1 NAME

Template::Declare::TagSet::RDF::EM - Template::Declare TAG set for Mozilla's em-rdf

=head1 SYNOPSIS

    # normal use on the user side:
    use base 'Template::Declare';
    use Template::Declare::Tags 'RDF::EM' => { namespace => 'em' }, 'RDF';

    template foo => sub {
        RDF {
            attr {
                'xmlns' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                'xmlns:em' => 'http://www.mozilla.org/2004/em-rdf#'
            }
            Description {
                attr { about => 'urn:mozilla:install-manifest' }
                em::id { 'foo@bar.com' }
                em::version { '1.2.0' }
                em::type { '2' }
                em::creator { 'Agent Zhang' }
            }
        }
    };

=head1 DESCRIPTION

Template::Declare::TagSet::RDF::EM defines a full set of Mozilla EM-RDF tags
for use in Template::Declare templates. You generally won't use this module
directly, but will load it via:

    use Template::Declare::Tags 'RDF::EM';

=head1 METHODS

=head2 new( PARAMS )

    my $html_tag_set = Template::Declare::TagSet->new({
        package   => 'EmRDF',
        namespace => 'em-rdf',
    });

Constructor inherited from L<Template::Declare::TagSet|Template::Declare::TagSet>.

=head2 get_tag_list

    my $list = $tag_set->get_tag_list();

Returns an array ref of all the RDF tags defined by
Template::Declare::TagSet::RDF. Here is the complete list:

=over

=item C<aboutURL>

=item C<contributor>

=item C<creator>

=item C<description>

=item C<developer>

=item C<file>

=item C<hidden>

=item C<homepageURL>

=item C<iconURL>

=item C<id>

=item C<locale>

=item C<localized>

=item C<maxVersion>

=item C<minVersion>

=item C<name>

=item C<optionsURL>

=item C<package>

=item C<requires>

=item C<skin>

=item C<targetApplication>

=item C<targetPlatform>

=item C<translator>

=item C<type>

=item C<updateURL>

=item C<version>

=back

This list may be not exhaustive; if you find some important missing ones,
please let us know. :)

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>

=head1 SEE ALSO

L<Template::Declare::TagSet>, L<Template::Declare::TagSet::RDF>, L<Template::Declare::TagSet::XUL>, L<Template::Declare::Tags>, L<Template::Declare>.

