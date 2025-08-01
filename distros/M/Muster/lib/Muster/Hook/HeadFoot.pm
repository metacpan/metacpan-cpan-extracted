package Muster::Hook::HeadFoot;
$Muster::Hook::HeadFoot::VERSION = '0.93';
use Mojo::Base 'Muster::Hook';
use Muster::LeafFile;
use Muster::Hooks;

use Carp 'croak';

=encoding utf8

=head1 NAME

Muster::Hook::HeadFoot - Muster header and footer hook.

=head1 VERSION

version 0.93

=head1 DESCRIPTION

L<Muster::Hook::HeadFoot> includes header and footer pages inside pages.

=head1 METHODS

=head2 register

Do some intialization.
And register.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{metadb} = $hookmaster->{metadb};

    $hookmaster->add_hook('headfoot' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process header/footer inclusion.

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    # Don't do header/footer inclusion in the scanning phase;
    # it would be too confusing.
    if ($phase eq $Muster::Hooks::PHASE_SCAN)
    {
        return $leaf;
    }

    my $pagename = $leaf->pagename;

    # Do a naive solution first: simply include the raw text of the other pages
    # into this page, IFF they are of the same filetype.
    # This ought to work in most cases, if I'm sticking to Markdown for the default page type.
    # If this is a binary file, use the "html_from" value if it exists.
    my %affix = ();
    $affix{header}->{pagename} = $self->_find_affix_page(current_page=>$pagename,
        affix_page=>'_Header');
    $affix{footer}->{pagename} = $self->_find_affix_page(current_page=>$pagename,
        affix_page=>'_Footer');

    my $this_filetype = ($leaf->is_binary
        ? (defined $leaf->meta->{html_from} and $leaf->meta->{html_from}
            ? $leaf->meta->{html_from} : $leaf->filetype)
        : $leaf->filetype);
    foreach my $type (keys %affix)
    {
        my $page = $affix{$type}->{pagename};
        if ($page)
        {
            my $info = $self->{metadb}->page_or_file_info($page);
            if ($info and $info->{filetype} eq $this_filetype)
            {
                my $new_leaf = Muster::LeafFile->new(
                    pagename=>$info->{pagename},
                    pagesrcname=>$info->{pagesrcname},
                    parent_page=>$info->{parent_page},
                    filename=>$info->{filename},
                    filetype=>$info->{filetype},
                    is_binary=>$info->{is_binary},
                    extension=>$info->{extension},
                    bald_name=>$info->{bald_name},
                    hairy_name=>$info->{hairy_name},
                    title=>$info->{title},
                    date=>$info->{date},
                    meta=>$info,
                );
                $new_leaf = $new_leaf->reclassify();
                if (!$new_leaf)
                {
                    croak "ERROR: leaf did not reclassify\n";
                }
                $affix{$type}->{contents} = $new_leaf->raw;
            }
        }
    }

    # Now include the header and footer if there is one
    if ($affix{header}->{contents})
    {
        $leaf->{cooked} = $affix{header}->{contents} . $leaf->{cooked};
    }
    if ($affix{footer}->{contents})
    {
        $leaf->{cooked} = $leaf->{cooked} . $affix{footer}->{contents};
    }

    return $leaf;
} # process

=head2 _find_affix_page

Find the desired Header/Footer page which
applies to the given page.
First search in the same level as the page, then in its
parent level, and so on.

    my $spage = $self->_find_affix_page(current_page=>$page,affix_page=>'_Header');

=cut
sub _find_affix_page {
    my $self = shift;
    my %args = @_;

    my $current_page = $args{current_page};
    my $affix_page = $args{affix_page};
    my $cp_info = $self->{metadb}->page_or_file_info($current_page);

    # find a "local" affix-page first, which has priority
    # This will have an extra '_' at the front of it.
    # This can only be in the same folder as the current page.
    my $local_sp = $cp_info->{parent_page} . '/_' . $affix_page;
    if ($self->{metadb}->page_exists($local_sp))
    {
        return $local_sp;
    }

    # Next priority is a grand-local page.
    # This is in the directory *above* this page (grandparent)
    # and has two extra '_' at the front of it.
    my $grandlocal_sp = $cp_info->{grandparent_page} . '/__' . $affix_page;
    if ($self->{metadb}->page_exists($grandlocal_sp))
    {
        return $grandlocal_sp;
    }

    my @bits = split('/', $current_page);
    my $found_page = '';
    do {
        my $cwd = join('/', @bits);
        my $q = "SELECT page FROM pagefiles WHERE bald_name = '$affix_page' AND parent_page IN (SELECT parent_page FROM pagefiles WHERE page = '$cwd');";
        my $pages = $self->{metadb}->query($q);
        if ($pages)
        {
            $found_page = $pages->[0];
        }
        pop @bits;
    } while (scalar @bits and !$found_page);

    return $found_page;
} # _find_affix_page

1;
