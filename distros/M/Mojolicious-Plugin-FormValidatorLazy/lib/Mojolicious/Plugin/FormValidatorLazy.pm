package Mojolicious::Plugin::FormValidatorLazy;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
our $VERSION = '0.03';
use Data::Dumper;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw{encode decode xml_escape hmac_sha1_sum secure_compare
                                                        b64_decode b64_encode};
use HTML::ValidationRules::Legacy qw{validate extract};

our $TERM_ACTION = 0;
our $TERM_SCHEMA = 1;

### ---
### register
### ---
sub register {
    my ($self, $app, $opt) = @_;
    
    my $schema_key = $opt->{namespace}. "-schema";
    my $sess_key = $opt->{namespace}. '-sessid';
    
    my $actions = ref $opt->{action} ? $opt->{action} : [$opt->{action}];
    
    $app->hook(before_dispatch => sub {
        my $c = shift;
        my $req = $c->req;
        
        if ($req->method eq 'POST' && grep {$_ eq $req->url->path} @$actions) {
            
            my $wrapper = deserialize(unsign(
                $req->param($schema_key),
                ($c->session($sess_key) || ''). $app->secrets->[0]
            ));
            
            $req->params->remove($schema_key);
            
            if (!$wrapper) {
                return $opt->{blackhole}->($c,
                            'Form schema is missing, possible hacking attempt');
            }
            if ($req->url->path ne $wrapper->{$TERM_ACTION}) {
                return $opt->{blackhole}->($c,
                                        'Action attribute has been tampered');
            }
            
            if (my $err = validate($wrapper->{$TERM_SCHEMA}, $req->params)) {
                return $opt->{blackhole}->($c, $err);
            }
        }
    });
    
    $app->hook(after_dispatch => sub {
        my $c = shift;
        
        if ($c->res->headers->content_type =~ qr{^text/html} &&
                                                $c->res->body =~ qr{<form\b}i) {
            
            my $sessid = $c->session($sess_key);
            
            if (! $sessid) {
                $sessid = hmac_sha1_sum(time(). {}. rand(), $$);
                $c->session($sess_key => $sessid);
            }
            
            $c->res->body(inject(
                $c->res->body,
                $actions,
                $schema_key,
                $sessid. $app->secrets->[0],
                $c->res->content->charset)
            );
        }
    });
}

sub inject {
    my ($html, $actions, $token_key, $secret, $charset) = @_;
    
    if (! ref $html) {
        $html = Mojo::DOM->new($charset ? decode($charset, $html) : $html);
    }

    $html->find(qq{form[action][method="post"]})->each(sub {
        my $form    = shift;
        my $action  = $form->attr('action');
        
        return if (! grep {$_ eq $action} @$actions);
        
        my $wrapper = sign(serialize({
            $TERM_ACTION    => $action,
            $TERM_SCHEMA    => extract($form, $charset),
        }), $secret);
        
        $form->append_content(sprintf(<<"EOF", $token_key, xml_escape $wrapper));
<div style="display:none">
    <input type="hidden" name="%s" value="%s">
</div>
EOF
    });
    
    return encode($charset, $html);
}

sub serialize {
    return b64_encode(encode_json(shift // return), '');
}

sub deserialize {
    return decode_json(b64_decode(shift // return));
}

sub sign {
    my ($value, $secret) = @_;
    return $value. '--' . hmac_sha1_sum($value, $secret);
}

sub unsign {
    my ($value, $secret) = @_;
    if ($value && $secret && $value =~ s/--([^\-]+)$//) {
        my $sig = $1;
        return $value if (secure_compare($sig, hmac_sha1_sum($value, $secret)));
    }
    return;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::FormValidatorLazy - FormValidatorLazy

=head1 SYNOPSIS

    plugin form_validator_lazy => {
        namespace => 'form_validator_lazy',
        action => ['/receptor1'],
        blackhole => sub {
            my ($c, $error) = @_;
            app->log($error);
            $c->res->code(400);
            $c->render(text => 'An error occured');
        },
    };

=head1 DESCRIPTION

B<This software is considered to be alpha quality and isn't recommended for
regular usage.>

Mojolicious::Plugin::FormValidatorLazy is a Mojolicious plugin for validating
post data with auto-generated validation rules out of original forms.
It analizes the HTML forms before sending them to client, generate the schema,
inject it into original forms within a hidden fields so the plugin can detect
the schema when a post request comes.

The plugin detects following error for now.

=over

=item Unknown form fields.

The form fields represented by name attribute are all white listed and post data
injected unknown fields are blocked.

=item Unknown values of selectable fields.

Selectable values of checkboxes, radio buttons and select options are white
listed and unknow values are blocked.

The plugin also detects characteristics of tag types. Such as unchecked
checkboxes don't appear to data(not required), radio buttons can't be null only
when default value is offered(not null), and so on.

=item Hidden field tamperings.

Hidden typed input can't be ommited(required) and the value takes only one
option. the plugin blocks values against the schema.

=item Values against maxlength attributes.

Values violating of maxlength are blocked.

=item HTML5 validation attributes

HTML5 supports some validation attributes such as [required], [pattern=*],
[type=number], [min=*], [max=*]. The plugin detects them and block violations.

=item CSRF

This also detects CSRF.

=back

=head2 EXAMPLE

Run t/test_app.pl and try to attack the forms.

    ./t/test_app.pl daemon

=head2 CLASS METHODS

=head3 inject

Generates a schema strings of form structure for each forms in mojo response
and inject them into itself.

    my $injected = inject($html, $charset,
                                ['/path1', '/path2'], $token_key, $session_id);

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
