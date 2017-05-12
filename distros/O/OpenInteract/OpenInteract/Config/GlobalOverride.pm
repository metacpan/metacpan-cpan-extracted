package OpenInteract::Config::GlobalOverride;

# $Id: GlobalOverride.pm,v 1.8 2002/04/25 12:36:36 lachoy Exp $

use strict;
use OpenInteract::Config;

use constant DEBUG => 0;

########################################
# CLASS METHODS

sub new {
    my ( $class, $params ) = @_;
    my $self = bless( {}, $class );
    DEBUG && warn "Creating new override object\n";
    return $self->_read_rules( $params );
}


sub break_key {
    my ( $class, $key ) = @_;
    unless ( $key ) {
        die "Given rule does not have key, not processing\n";
    }
    return split /\./, $key;
}


########################################
# OBJECT METHODS

# \%params should have either 'filename' or 'content' defined.
# We're not using our INI reader because a) this is simpler and b) we
# need to allow multiple actions per key

sub _read_rules {
    my ( $self, $params ) = @_;
    my ( $lines );
    if ( $params->{filename} ) {
        $lines = OpenInteract::Config->read_file( $params->{filename} );
    }
    elsif ( $params->{content} ) {
        $lines = [ split /\n/, $params->{content} ];
    }
    else {
        die "Cannot read override rules without 'filename' or ",
            "'content' being defined\n";
    }

    my @rules = ();
    my ( $current_section, $current_rule );
    for ( @{ $lines } ) {
        chomp;
        s/\r//g;
        next if ( /^\s*$/ );
        next if ( /^\s*\#/ );
        s/\s+$//;
        s/^\s+//;

        # Encountered a key -- if we have a section/rule saved, stick
        # that into our rule list and reset the section.

        if ( /^\s*\[\s*(\S|\S.*\S)\s*\]\s*$/) {
            if ( $current_section and $current_rule ) {
                push @rules, $current_rule;
            }
            $current_section = $1;
            $current_rule    = { key => $current_section };
            next;
        }

        # Otherwise, we should have a key/value pair. If a value
        # already exists for that key, make it an arrayref. (Future:
        # make all values arrayrefs)

        my ( $param, $value ) = /^\s*([^=]+?)\s*=\s*(.*)\s*$/;
        my $existing = $current_rule->{ $param };
        if ( $existing and ref $existing eq 'ARRAY' ) {
            push @{ $current_rule->{ $param } }, $value;
        }
        elsif ( $existing ) {
            $current_rule->{ $param } = [ $existing, $value ];
        }
        else {
            $current_rule->{ $param } = $value;
        }
    }

    # Stick the last rule into our rule list and set into the object

    push @rules, $current_rule;
    $self->rules( \@rules );

    return $self;
}


# Get/set for the override rules

sub rules {
    my ( $self, $rules ) = @_;
    if ( $rules ) { $self->{_rules} = $rules; }
    return $self->{_rules};
}


# Get an arrayref of override keys.

sub override_keys {
    my ( $self ) = @_;
    return [ map { $_->{key} } @{ $self->{_rules} } ];
}


# Main method: apply the set of override rules to a passed-in
# configuration

sub apply_rules {
    my ( $self, $config ) = @_;
    foreach my $rule ( @{ $self->rules } ) {
        next unless ( ref $rule eq 'HASH' and keys %{ $rule } );

        # For the processors: put the key inside the rule and ensure
        # that 'value' is always an arrayref

        $rule->{value} = ( ref $rule->{value} eq 'ARRAY' )
                           ? $rule->{value}
                           : [ $rule->{value} ];

        # Process this rule

        if ( $rule->{action} eq 'add' ) {
            $self->_key_iterate( $rule, $config,
                                 { last_key   => \&_add_action,
                                   autovifify => 'yes' } );
        }
        elsif ( $rule->{action} eq 'remove' ) {
            $self->_key_iterate( $rule, $config,
                                 { last_key   => \&_remove_action,
                                   autovivify => 'no' } );
        }
        elsif ( $rule->{action} eq 'replace' ) {
            unless ( $rule->{replace} ) {
                die "Rule 'replace' for the key [$rule->{key}] ",
                    "must have a value for the 'replace' key.\n";
            }
            $self->_key_iterate( $rule, $config,
                                 { last_key   => \&_replace_action,
                                   autovifify => 'no' } );
        }
    }
}


# Split apart the key in $rule->{key} and traverse $config; once we've
# reached the last key (where we should do something), execute the
# callback passed in $params->{last_key}. Caller should also specify
# whether we should autovifify keys as we traverse $config if a key
# isn't found -- 'yes' we should, 'no' we die.

sub _key_iterate {
    my ( $self, $rule, $config, $params ) = @_;

    my @keys = $self->break_key( $rule->{key} );
    unless ( scalar @keys ) {
        die "No keys found from [$rule->{key}]\n";
    }

    my $item = $config;
    my $num_keys = scalar @keys;

    for ( my $i = 0; $i < $num_keys; $i++ ) {
        my $key = $keys[ $i ];

        # If the top-level key doesn't exist and there's more than one
        # key then we don't do anything. This means we shouldn't
        # autovivify top-level configuration items.

        if ( $i == 0 and $num_keys > 1 and ! $item->{ $key } ) {
            DEBUG && warn "Skipping [$rule->{ $key }] since the top level ",
                          "doesn't exist and there are [$num_keys] keys\n";
            last;
        }

        # Run the last key action

        if ( $i == $num_keys - 1 ) {
            $params->{last_key}->( $rule, $item, $key );
            next;
        }

        # Otherwise climb down...

        # if we're supposed to autovivify, create the key to climb
        # down, otherwise die

        unless ( $item->{ $key } ) {
            if ( $params->{autovifify} eq 'yes' ) {
                $item->{ $key } = {};
            }
            else {
                die "The key specified in '$rule->{action}' for ",
                    "[$rule->{key}] must already exist. (Nothing ",
                    "for [$key])\n";
            }
        }
        $item = $item->{ $key };
    }
}


# Action to execute when we find the last key for an 'add'

sub _add_action {
    my ( $rule, $item, $key ) = @_;
    DEBUG && warn "Adding to [$key]: ", join( ', ', @{ $rule->{value} } ), "\n";
    my $type = $rule->{type};
    unless ( $type ) {
        $type = 'list'  if ( ref $item->{ $key } eq 'ARRAY' );
        $type = 'hash'  if ( ref $item->{ $key } eq 'HASH' );
    }

    unless ( $item->{ $key } ) {
        $item->{ $key } = []  if ( $type eq 'list' );
    }

    if ( $type eq 'list' ) {
        unless ( ref $item->{ $key } eq 'ARRAY' ) {
            $item->{ $key } = ( defined $item->{ $key } )
                                ? [ $item->{ $key } ] : [];
        }
        my $queue = $rule->{queue} || 'back';
        if ( $queue eq 'front' ) {
            unshift @{ $item->{ $key } }, @{ $rule->{value} };
        }
        else {
            push @{ $item->{ $key } }, @{ $rule->{value} };
        }
    }
    else {
        $item->{ $key } = $rule->{value}[0];
    }
}


# Action to execute when we find the last key for a 'remove'

sub _remove_action {
    my ( $rule, $item, $key ) = @_;
    DEBUG && warn "Removing from [$key]: ", join( ', ', @{ $rule->{value} } ), "\n";
    unless ( $item->{ $key } ) {
        delete $item->{ $key };
        return;
    }
    my $type = $rule->{type};
    unless ( $type ) {
        $type   = 'list'   if ( ref $item->{ $key } eq 'ARRAY' );
        $type   = 'hash'   if ( ref $item->{ $key } eq 'HASH' );
        $type ||= 'scalar';
    }

    # If there are no values, just delete the key entirely

    unless ( $rule->{value}[0] ) {
        delete $item->{ $key };
        return;
    }

    # Otherwise cycle through the values and do the right thing

    foreach my $value ( @{ $rule->{value} } ) {
        if ( $type eq 'list' ) {
            $item->{ $key } = [ grep { $_ ne $value }
                                     @{ $item->{ $key } } ];
        }
        elsif ( $type eq 'hash' ) {
            delete $item->{ $key }{ $value };
        }
        else {
            delete $item->{ $key };
        }
    }
}

# Action to execute when we find the last key for a 'replace'

sub _replace_action {
    my ( $rule, $item, $key ) = @_;
    unless ( ref $item->{ $key } eq 'ARRAY' ) {
        die "The rule 'replace' can only be applied to lists. ",
            "The value in the key [$rule->{key}] is not a list.\n";
    }
    DEBUG && warn "Replacing from [$key]: [$rule->{replace}] with [",
                  join( ', ', @{ $rule->{value} } ), "] with existing ",
                  "values [", join( ', ', @{ $item->{ $key } } ), "]\n";
    my @new_list = ();
    foreach my $existing ( @{ $item->{ $key } } ) {
        if ( $existing eq $rule->{replace} ) {
            push @new_list, @{ $rule->{value} };
        }
        else {
            push @new_list, $existing;
        }
    }
    DEBUG && warn "Resulting replaced values [",
                  join( ', ', @new_list ), "]\n";
    $item->{ $key } = \@new_list;
}

1;

__END__

=pod

=head1 NAME

OpenInteract::Config::GlobalOverride -- Process global override settings for a set of configuration directives

=head1 SYNOPSIS

 ## ----------Sample of an override file----------

 # Add a new value to 'user.track'

 [user.track.finalize]
 action  = add
 value   = 1

 # Add two new entries to the ruleset for the 'news' object, giving
 # the system a hint as to what type of data it should be

 [news.rules_from]
 action  = add
 value   = OpenInteract::RSSArticleSummarize
 value   = OpenInteract::EditorApproval
 type    = list

 # Remove 'SPOPS::Secure' from 'page.isa' list

 [page.isa]
 action  = remove
 value   = SPOPS::Secure

 # Remove key and value for 'uid' from 'user.field_map' hash

 [user.field_map]
 action  = remove
 value   = uid

 # Remove the entire 'field_alter' hashref
 [user.field_alter]
 action  = remove

 # Replace 'SPOPS::DBI::MySQL with 'SPOPS::DBI::Pg' in all keys that
 # have an 'isa' entry

 [*.isa]
 action  = replace
 replace = SPOPS::DBI::MySQL
 value   = SPOPS::DBI::Pg

 # Replace 'SPOPS::DBI::MySQL with 'SPOPS::DBI::Sybase' in the
 # 'user.isa' list

 [user.isa]
 action  = replace
 replace = SPOPS::DBI::MySQL
 value   = SPOPS::DBI::Sybase

 ## ----------End sample override file----------

 ## Read in a configuration and apply the override file, saved for
 ## this example in global_override.ini

 my $config = OpenInteract::Config->new(
                         'ini', { filename => 'server.ini' } );
 my $override_file = join( '/', $config->{dir}{config},
                                'global_override.ini' );
 my $override = OpenInteract::Config::GlobalOverride->new( $override_file );
 $override->apply_rules( $config );

 ## Values in $config are now modified based on the given rules

=head1 DESCRIPTION

This class allows you to define a set of override rules and apply them
to a configuration. This is very helpful in OpenInteract because large
sections of the server configuration are pieced together from
information in a number of packages. Since there can be any number of
packages -- at least 14, and most likely more -- modifying each of
these is time-consuming and error-prone. Additionally, you need to
modify the configuration for a package every time you upgrade.

Instead of this hassle, you can now define rules in a single file that
will modify any configuration value. You have three ways to do this:

=over 4

=item * B<add>: Add/overwrite a value to an existing list or hash.

=item * B<remove>: Remove a particular value from a list, or delete a
hash key.

=item * B<replace>: Replace a value with another in a list.

=back

=head2 Action: Add

=head2 Action: Remove

=head2 Action: Replace

=head1 METHODS

=head2 Class Methods

B<new( $rule_filename )>

=head2 Object Methods

B<apply_rules( $config )>

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

=head1 COPYRIGHT

Copyright (c) 2002 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters <chris@cwinters.com>

=cut


