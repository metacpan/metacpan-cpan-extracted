use strictures 1;
package Mojito::Page::Parse;
$Mojito::Page::Parse::VERSION = '0.25';
use 5.010;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Data::Dumper::Concise;

=head1 Name

Mojito::Page::Parse - turn page source into a page structure

=cut

# This is the page source
has 'page' => (
    is       => 'rw',
    isa      => Value,
);
has 'sections' => (
    is      => 'ro',
    isa     => ArrayRef[HashRef],
    lazy    => 1,
    builder => 'build_sections',
);
has 'page_structure' => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'build_page_structure',
);
has 'default_format' => (
    is => 'rw',
    isa     => Value,
    lazy => 1,
    default => sub { 'HTML' },
);
has 'created' => (
    is  => 'ro',
    isa => Int,
);
has 'last_modified' => (
    is      => 'ro',
    isa     => Int,
    default => sub { time() },
);
has 'section_open_regex' => (
    is      => 'ro',
    isa     => RegexpRef,
    default => sub { qr/<sx\.[^>]+>/ },
);
has 'section_close_regex' => (
    is      => 'ro',
    isa     => RegexpRef,
    default => sub { qr(</sx>) },
);
has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
);
has 'messages' => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);
has 'message_string' => (
    is => 'ro',
    isa => Value,
    lazy => 1,
    builder => '_build_message_string',
);
sub _build_message_string {
    my ($self) = (shift);
    return join ', ', @{$self->messages} if $self->messages;
    return;
}

=head2 has_nested_section

Test if we have nested sections.

=cut

sub has_nested_section {
    my ($self) = @_;

    my $section_open_regex  = $self->section_open_regex;

    #die "Got no page" if !$self->page;
    my @stuff_between_section_opens =
      $self->page =~ m/${section_open_regex}(.*?)${section_open_regex}/si;

    # If when find a section ending tag in the middle of the two consecutive
    # opening section tags then we know first section has been closed and thus
    # does NOT contain a nested section.
    foreach my $tweener (@stuff_between_section_opens) {
        if ( $tweener =~ m/<\/sx>/ ) {

   # The tweener section could cause us to think we're not nested
   # due to an nested section of the general type (not the class=mc_ type)
   # In this case we need to count the number of open and closed sections
   # If they are the same then we dont' have </sec> left over to close the first
   # and thus we have a nest.
            my @opens  = $tweener =~ m/(<sx[^>]*>)/sg;
            my @closes = $tweener =~ m/(<\/sx>)/sg;
            if ( scalar @opens == scalar @closes ) {
                return 1;
            }
        }
        else {
            return 1;
        }
    }

    return 0;
}

=head2 add_implicit_sections

Add implicit sections to assist the building of the page_struct.

=cut

sub add_implicit_sections {
    my ($self) = @_;

    my $page                = $self->page;

    # Add implicit sections in between explicit sections (if needed)
    if ( $page =~ m/<\/sx>(?!\s*<sx\.).*?<sx\./si ) {
        $page =~ s/<\/sx>(?!\s*<sx\.)(.*?)<sx\./<\/sx>\n<sx.Implicit>$1<\/sx>\n<sx./sig;
    }

    # Add implicit section at the beginning (if needed)
    $page =~ s/(?<!<sx\.\w)(<sx\.\w)/<\/sx>\n$1/si;
    $page = "\n<sx.Implicit>\n${page}";

    # Add implicit section at the end (if needed)
    $page =~ s/(<\/sx>)(?!.*<\/sx>)/$1\n<sx.Implicit>/si;
    $page .= '</sx>';

    # cut empty implicits
    $page =~ s/<sx\.Implicit>\s*<\/sx>//sig;

    if ( $self->debug ) {
        say "PREMATCH: ", ${^PREMATCH};
        say "MATCH:  ${^MATCH}";
        say "POSTMATCH: ", ${^POSTMATCH};
        say "page: $page";
    }

    return $page;
}

=head2 parse_sections

Extract section class and content from the page.

=cut

sub parse_sections {
    my ( $self, $page ) = @_;

    my $sections;
    my @sections = $page =~ m/(<sx\.[^>]+>.*?<\/sx>)/sig;
    foreach my $sx (@sections) {

        # Extract class and content
        my ( $class, $content ) = $sx =~ m/<sx\.([^>]+)>(.*)?<\/sx>/si;
        push @{$sections}, { class => $class, content => $content };
    }

    return $sections;
}

=head2 build_sections

Wrap up the getting of sections process.

=cut

sub build_sections {
    my $self = shift;

    # Deal with nested sections gracefully by adding a message
    # to bubble up to the view and display in the #message_area.
    if ( $self->has_nested_section ) {
        $self->messages( [ @{$self->messages}, 'haz nested sexes'] );
    }
    my $page = $self->add_implicit_sections;

    return $self->parse_sections($page);
}

=head2 build_page_structure

It's just an href that we'll persist as a Mongo document.

=cut

sub build_page_structure {
    my $self = shift;

    my $return = {
        sections       => $self->sections,
        default_format => $self->default_format,

        #        created        => '1234567890',
        #        last_modified  => time(),
        page_source    => $self->page,

        # Set the message last to pick any builder message above
        # e.g. ->sections can set a 'nested sections' message.
        message        => $self->message_string,
    };
    return $return;
}

1
