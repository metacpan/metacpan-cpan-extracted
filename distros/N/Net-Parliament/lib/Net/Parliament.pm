package Net::Parliament;
use Moose;
use Net::Parliament::UserAgent;
use HTML::TableExtract qw/tree/;
use HTML::TreeBuilder;
use XML::Simple;

=head1 NAME

Net::Parliament - Scrape data from parl.gc.ca

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module will fetch HTML and XML from parl.gc.ca,
and then parse it into hashrefs.

    use Net::Parliament;

    my $parl = Net::Parliament->new(
        parliament => 40,
        session    => 2,
    );
    my $members = $parl->members();

=cut

has '_members_base_url' => (
    is      => 'ro', isa => 'Str',
    default => 'http://webinfo.parl.gc.ca/MembersOfParliament/',
);

has 'members_html_url' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        shift->_members_base_url
            . 'MainMPsCompleteList.aspx?TimePeriod=Current';
    },
);

has '_bills_base_domain' => (
    is      => 'ro', isa => 'Str',
    default => 'http://www2.parl.gc.ca',
);

has '_bills_base_url' => (
    is      => 'ro', isa => 'Str',
    default => 'http://www2.parl.gc.ca/HouseBills/billsgovernment.aspx?',
);

has '_bill_votes_base_url' => (
    is      => 'ro', isa => 'Str',
    default => 'http://www2.parl.gc.ca/housebills/BillVotes.aspx?xml=True&SchemaVersion=1.0',
);

has 'ua' => (
    is      => 'ro',
    isa     => 'Object',
    handles => ['get'],
    default => sub { Net::Parliament::UserAgent->new },
);

has 'parliament' => (is => 'rw', isa => 'Int', required => 1);
has 'session'    => (is => 'rw', isa => 'Int', required => 1);

=head1 METHODS

=head2 members(%opts)

This method returns an arrayref containing a hashref for each
member of parliament.  Fetching the data is cached via
Net::Parliament::UserAgent.

Options:

=over 4

=item extended

If set to true, extra data from the member's home page will
be fetched.  This takes much longer.

=item limit

Only return this number of results.  Useful for testing.

=back

=cut

sub members {
    my $self = shift;
    my %opts = @_;

    my $members_page = $self->get($self->members_html_url);

    my $te = HTML::TableExtract->new( 
        headers => [ 'Member of Parliament', 'Constituency', 
                     'Province/Territory', 'Caucus' ],
    );
    $te->parse($members_page);

    my ($member_table) = $te->tables;
    my $table_tree = $member_table->tree;

    my @members;
    my $max = $opts{limit} || $table_tree->maxrow;
    $max = $table_tree->maxrow if $max > $table_tree->maxrow;
    for my $i (1 .. $max) {
        my $row = $table_tree->row($i);
        my @cols =$row->look_down('_tag', 'td');

        my $member = {};
        eval {
            $member->{member_url}
                = $self->_members_base_url
                . $cols[0]->find_by_tag_name('a')->attr('href');
            $member->{member_name}
                = $cols[0]->find_by_tag_name('a')->content->[0];
            $member->{constituency}
                = $cols[1]->find_by_tag_name('a')->content->[0];
            $member->{province} = $cols[2]->content->[0];
            $member->{caucus}   = $cols[3]->content->[0];
            if (ref($member->{caucus})) {
                $member->{caucus} = $member->{caucus}->content->[0];
            }
            if ($member->{member_url} =~ m/Key=(\d+)/) {
                $member->{member_id} = $1;
            }
        };
        if ($@) {
            warn "Error parsing row: $@";
            $row->dump;
        }

        $member = $self->_load_member($member)
            if $opts{extended};
        push @members, $member;
    }

    return \@members;
}

=head2 bills()

This method returns an arrayref containing a hashref for each
Government Bill raised in parliament.  

=cut

sub bills {
    my $self = shift;
    my $p = $self->parliament;
    my $s = $self->session;

    my $url = $self->_bills_base_url . "Parl=$p&Ses=$s";
    my $html = $self->get($url);
    my $block_oh_html = <<EOT;
<div class="BillBlock BillBlockOdd" id="divBillBlockC2">
 <span class="BillNumberCell">C-2</span>
 <div class="BillSummary">
  <span class="BillLongText">An Act to amend the Criminal Code and to make consequential amendments to other Acts</span>
  <div class="BillSponsor"><a class="WebOption" onclick="GetWebOptions('PRISM','Affiliation',105824,'1');return false;" onmouseout="inDiv=0;setTimeout('TimeoutHide()',1000);return false;" href="/HousePublications/GetWebOptionsCallBack.aspx?SourceSystem=PRISM&amp;ResourceType=Affiliation&amp;ResourceID=105824&amp;language=1&amp;DisplayMode=2">The Minister of Justice</a></div>
  <div>
   <div><a class="BillVersionLink" href="/HouseBills/StaticLinkRedirector.aspx?Language=e&amp;LinkTitle=%28C-2%29%20Legislative%20Summary&amp;RedirectUrl=%2fSites%2fLOP%2fLEGISINFO%2findex.asp%3fList%3dls%26Language%3dE%26Query%3d5273%26Session%3d15&amp;RefererUrl=X&amp;StatsEnabled=true">Legislative Summary</a></div>
   <div><a class="BillVersionLink" href="/HousePublications/Publication.aspx?DocId=3078412&amp;Language=e&amp;Mode=1">First Reading</a></div>
   <div><a class="BillVersionLink" href="/HousePublications/Publication.aspx?DocId=3151626&amp;Language=e&amp;Mode=1">As passed by the House of Commons</a></div>
   <div><a class="BillVersionLink" href="/HousePublications/Publication.aspx?DocId=3320180&amp;Language=e&amp;Mode=1">Royal Assent</a></div>
   <div><a class="BillVersionLink" href="/housebills/BillVotes.aspx?Language=e&amp;Mode=1&amp;Parl=39&amp;Ses=2&amp;Bill=C2">Votes</a></div>
  </div>
 </div>
</div>
EOT

    my $tree = HTML::TreeBuilder->new_from_content($html);
    my @billblocks = $tree->look_down(class => qr/\bBillBlock\b/);
    my @bills;
    for my $b (@billblocks) {
        my $bill = {
            parliament => $p,
            session    => $s,
            name => $b->look_down(class => 'BillNumberCell')->content->[0],
            summary => $b->look_down(class => 'BillLongText')->content->[0],
            sponsor_title =>
                $b->look_down(class => 'BillSponsor')->content->[0]
        };

        if (ref($bill->{sponsor_title})) {
            my $bs = $bill->{sponsor_title};
            $bill->{sponsor_title} = $bs->content->[0];
            my $url = $bs->look_down(
                _tag => 'a')->attr('href');
            if ($url =~ m/ResourceID=(\d+)/) {
                $bill->{sponsor_id} = $1;
            }
        }

        my @links = $b->look_down(class => 'BillVersionLink');
        for my $link (@links) {
            my $url = $self->_bills_base_domain . $link->attr('href');
            $url =~ s/\s/%20/g;
            push @{ $bill->{links} }, { $link->content->[0] => $url };
        }

        push @bills, $bill;
    }
    return \@bills;
}

=head2 bill_votes( $bill_name )

This method returns an arrayref containing a hashref for each
vote on the specified Bill.

=cut

sub bill_votes {
    my $self = shift;
    my $bill = shift or die "Must specify a bill name";
    $bill =~ s/-//;
    my $p = $self->parliament;
    my $s = $self->session;

    my $url = $self->_bill_votes_base_url . "&Parl=$p&Ses=$s&Bill=$bill";
    my $xml = XMLin($self->get($url));
    
    return [] unless $xml->{Vote};
    return [ $xml->{Vote} ] if ref($xml->{Vote}) eq 'HASH';
    return $xml->{Vote};
}

=head2 member_votes( $member_id )

This method returns an arrayref containing a hashref for each
vote made by the specified member.

=cut

sub member_votes {
    my $self = shift;
    my $member = shift or die "Must specify a member ID";
    my $p = $self->parliament;
    my $s = $self->session;

    my $url = $self->_members_base_url 
        . "ProfileMP.aspx?key=$member&SubSubject=1006&"
        . "FltrParl=$p&FltrSes=$s&VoteType=1&"
        . 'xml=true&SchemaVersion=1.0';
    my $xml = XMLin($self->get($url));
    return $xml->{Vote};
}

sub _load_member {
    my $self       = shift;
    my $member     = shift;
    my $member_url = $member->{member_url};

    my $content = $self->get($member_url);
    eval {
        $member->{profile_photo_url} = $self->_extract_photo_url($content);
    };
    if ($@) {
        die "Couldn't extract profile photo from $member_url: $@\n";
    }
    eval {
        $self->_extract_more_details($content, $member);
    };
    if ($@) {
        die "Couldn't extract details from $member_url: $@\n";
    }

    return $member;
}

sub _extract_photo_url {
    my $self    = shift;
    my $content = shift;

    my $te = HTML::TableExtract->new( depth => 3, count => 1);
    $te->parse($content);

    my $profile_img;
    eval {
        my ($member_table) = $te->tables;
        my $row            = $member_table->tree->row(1);
        ($profile_img)  = $row->look_down('_tag', 'img');
    };
    if ($@) {
        die "Error finding profile image in content:\n$content\n\n";
    }
    return $self->_members_base_url . $profile_img->attr('src');
}

sub _extract_more_details {
    my $self    = shift;
    my $content = shift;
    my $member  = shift;

    my $te = HTML::TableExtract->new( depth => 5, count => 6);
    $te->parse($content);

    my ($details) = $te->tables;
    my $tree = $details->tree;

    for my $row (map { $tree->row($_) } 5 .. 8) {
        eval {
            my ($key, $val)
                = map { $_->content->[0]->content->[0] }
                $row->look_down('_tag', 'td');

            $key =~ s/:\*?$//;
            $key = lc($key);

            if ($key eq 'web site') {
                $val = 'http://' . $val;
            }

            $member->{$key} = $val;
        };
    }
}

=head1 AUTHOR

Luke Closs, C<< <cpan at 5thplane.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-parliament at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Parliament>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Parliament

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Parliament>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Parliament>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Parliament>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Parliament/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to parl.gc.ca for the parts of their site in XML format.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
