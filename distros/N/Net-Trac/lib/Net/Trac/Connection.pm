package Net::Trac::Connection;

=head1 NAME

Net::Trac::Connection - Connection to a remote Trac server

=head1 DESCRIPTION

This class represents a connection to a remote Trac instance.  It is
required by all other classes which need to talk to Trac.

=head1 SYNOPSIS

    use Net::Trac::Connection;

    my $trac = Net::Trac::Connection->new( 
        url      => 'http://trac.example.com',
        user     => 'snoopy',
        password => 'doghouse'
    );

=cut

use Any::Moose;

use URI;
use Params::Validate;
use Text::CSV;
use Net::Trac::Mechanize;

=head1 ACCESSORS

=head2 url

The url of the Trac instance used by this connection.  Read-only after
initialization.

=head2 user

=head2 password

=cut

has url => (
    isa => 'Str',
    is  => 'ro'
);

has user => (
    isa => 'Str',
    is  => 'ro'
);

has password => (
    isa => 'Str',
    is  => 'ro'
);

=head1 ACCESSORS / MUTATORS

=head2 logged_in [BOOLEAN]

Gets/sets a boolean indicating whether or not the connection is logged in yet.

=cut

has logged_in => (
    isa => 'Bool',
    is  => 'rw'
);

=head2 mech [MECH]

Gets/sets the L<Net::Trac::Mechanize> (or subclassed) object for this
connection to use.  Unless you want to replace it with one of your own,
the default will suffice.

=cut

has mech => (
    isa     => 'Net::Trac::Mechanize',
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $m    = Net::Trac::Mechanize->new( cookie_jar => {}, keep_alive => 4);
        $m->trac_user( $self->user );
        $m->trac_password( $self->password );
        return $m;
    }
);

=head1 METHODS

=head2 new PARAMHASH

Creates a new L<Net::Trac::Connection> given a paramhash with values for
the keys C<url>, C<user>, and C<password>.

=head2 ensure_logged_in

Ensures this connection is logged in.  Returns true on success, and undef
on failure.  Sets the C<logged_in> flag.

=cut

sub ensure_logged_in {
    my $self = shift;
    if ( !defined $self->logged_in ) {
        $self->_fetch("/login") or return;

        my ($form, $form_num) = $self->_find_login_form();
    if ($form_num) {
        $self->mech->submit_form(
        form_number => $form_num,
        fields => { user => $self->user, password => $self->password, submit => 1 }
     );
        }
 
        
        $self->logged_in(1);
    }
    return $self->logged_in;
}


sub _find_login_form {
    my $self = shift;
        my $i = 1;
        for my $form ( $self->mech->forms() ) {
                return ($form,$i) if $form->find_input('user');
                 $i++;
        }
}


=head1 PRIVATE METHODS

=head2 _fetch URL

Fetches the provided B<relative> URL from the Trac server.  Returns undef
on an error (after C<warn>ing) and the content (C<$self->mech->content>)
on success.

=cut

sub _fetch {
    my $self    = shift;
    my $query   = shift;
    my $abs_url = $self->url . $query;
    $self->mech->get($abs_url);

    if ( $self->_warn_on_error($abs_url) ) { warn "Failed to fetch $abs_url"; return }
    else { return $self->mech->content }
}

=head2 _warn_on_error URL

Checks the last request for an error condition and warns about them if found.
Returns with a B<TRUE> value if errors occurred and a B<FALSE> value otherwise
for nicer conditionals.

=cut

sub _warn_on_error {
    my $self = shift;
    my $url  = shift;
    my $die  = 0;

    if ( !$self->mech->response->is_success ) {
        warn "Server threw an error "
             . $self->mech->response->status_line . " for "
             . $url . "\n";
        $die++;
    }

    if (
        $self->mech->content =~ qr{
    <div id="content" class="error">
          <h1>(.*?)</h1>
            <p class="message">(.*?)</p>}ism
        )
    {
        warn "$1 $2\n";
        $die++;
    }

    # Returns TRUE if it got an error, for nicer conditionals when calling
    if ( $die ) { warn "Request errored out.\n"; return 1; }
    else        { return }
}

=head2 _tsv_to_struct PARAMHASH

Takes a paramhash of the keys C<data>
Given TSV data this method will return a reference to an array.

=cut

sub _tsv_to_struct {
    my $self = shift;
    my %args = validate( @_, { data => 1 } );
    my $lines    = ${ $args{'data'} };

    open (my $io, "<",\$lines) || die "Couldn't open in-memory file to data: $!";
    my $csv = Text::CSV->new({binary => 1, sep_char => "\t" });
         $csv->column_names ($csv->getline ($io));
    my @results;
    while (my $hr = $csv->getline_hr ($io)) {
        push @results, $hr;
    }
    close($io)||die $!;
    return \@results;
}

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
