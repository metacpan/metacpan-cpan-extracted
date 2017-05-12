package Net::Google::Code::Role::Predefined;
use Any::Moose 'Role';
use Params::Validate ':all';
use JSON;
with 'Net::Google::Code::Role::Fetchable';

has 'predefined_status' => (
    isa => 'HashRef',
    is  => 'rw',
);

has 'predefined_labels' => (
    isa => 'ArrayRef',
    is  => 'rw',
);

no Any::Moose;

sub load_predefined {
    my $self = shift;
    my $class = ref $self || $self;
    my $last_name;
    $last_name = lc $1 if $class =~ /::(\w+)$/;

    return unless $self->signed_in;
    my $base_url = $self->base_url;
    my $content = $self->fetch($self->base_url);
    if ( $content =~ /codesite_token\s*=\s*"(\w+)"/ ) {
        my $token = $1;
        my $mech = $self->mech;
# I tried to use $mech->post( $url, token => $token )
# but without luck :(
        $mech->update_html(<<"EOF");
<form action="${base_url}feeds/${last_name}OptionsJSON"
method="POST" >
<input type="text" name="token" value="$token" />
<input type="submit" value="submit" />
</form>
EOF
        $mech->submit_form( form_number => 1 );
        die "failed to post to OptionsJSON page" unless $mech->success;

        my $js     = $mech->content;
        my $object = from_json $js;
        return unless $object;

        $self->predefined_status( { open => [], closed => [] } );
        for my $type (qw/open closed/) {
            for ( @{ $object->{$type} } ) {
                push @{ $self->predefined_status->{$type} }, $_->{name};
            }
        }

        $self->predefined_labels( [] );
        for ( @{ $object->{labels} } ) {
            push @{ $self->predefined_labels }, $_->{name};
        }

        return 1;
    }
    else {
        warn "can't get user token";
        return;
    }

}

1;

__END__

=head1 NAME

Net::Google::Code::Role::Predefined - Predefined Role


=head1 DESCRIPTION

=head1 INTERFACE

=over 4

=item load_predefined

=back

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


