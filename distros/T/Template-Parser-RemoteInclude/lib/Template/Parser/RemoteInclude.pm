package Template::Parser::RemoteInclude;

use strict;
use warnings;

our $VERSION = '0.01';

use namespace::autoclean;
use AnyEvent;
use AnyEvent::Curl::Multi;
use HTTP::Request;
use Scalar::Util qw(refaddr);
use Try::Tiny;
use Sub::Install;

use base 'Template::Parser';

# парсер ничего не знает о переменных, которые будут проинициализированы в шаблоне, т.к. он его ещё разбирает,
# но, вот получить хэш переменных - вполне необходимо, дабы упростить использование модуля
$Template::Parser::RemoteInclude::old_tt_process = \&Template::process;
Sub::Install::reinstall_sub({
   code => sub {
       my $providers = $_[0]->service->context->{ LOAD_TEMPLATES };
       for (@$providers) {
           next unless $_;
           if (UNIVERSAL::isa($_->{PARSER},'Template::Parser::RemoteInclude')) {
               $_->{PARSER}->{__stash} = $_[2] || {};
               last;
           };
       }
       return $Template::Parser::RemoteInclude::old_tt_process->(@_); 
   },
   into => "Template",
   as   => "process",
});


=head1 NAME

Template::Parser::RemoteInclude - call remote template-server inside your template

=head1 DESCRIPTION

You can write your own html aggregator for block build pages. 
However, this module allows you to make remote calls directly from the template. 
This is very useful when your project have a template server.

This module allows you to make any http-requests from template.

Depends on L<Template::Parser> and L<AnyEvent::Curl::Multi>. 

L<Curl::Multi> faster than L<LWP>. L<AnyEvent::Curl::Multi> much faster than L<LWP> ;)

Use and enjoy!

=head1 NOTE

=over 4

=item *

Directive C<RINCLUDE> like C<PROCESS>, but call remote uri.

=item *

Parser does not know anything about L<Template::Stash>, but knows about the variables passed in C<Template::process>.

=item *

Content of the response can be as a simple html or a new template

=item *

Contents of the response is recursively scanned for directives C<RINCLUDE> and makes additional request if necessary

=item *

The best option when your template-server is located on the localhost

=back

=head1 SYNOPSIS

create C<Template> object with C<Template::Parser::RemoteInclude> as parser.

    use Template;
    use Template::Parser::RemoteInclude;
    
    my $tt = Template->new(
         INCLUDE_PATH => '....',
         ....,
         PARSER       => Template::Parser::RemoteInclude->new(
             'Template::Parser' => {
                 ....,
             },
             'AnyEvent::Curl::Multi' => {
                max_concurrency => 10,
                ....,
             }
         )
    );

simple example include content C<http://ya.ru/> (with GET as http method)

    # example 1
    my $tmpl = "[% RINCLUDE GET 'http://ya.ru/' %]";
    $tt->process(\$tmpl,{});
    
    # example 2 - use variables passed in Template::process
    my $tmpl = "[% RINCLUDE GET ya_url %]";
    $tt->process(\$tmpl,{ya_url => 'http://ya.ru/'});
    
    # example 3 - set headers
    my $tmpl = "[% RINCLUDE GET ya_url ['header1' => 'value1','header2' => 'value2'] %]";
    $tt->process(\$tmpl,{ya_url => 'http://ya.ru/'});
    
    # example 4 - set headers
    my $tmpl = "[% RINCLUDE GET ya_url  headers %]";
    $tt->process(\$tmpl,{ya_url => 'http://ya.ru/', headers => ['header1' => 'value1','header2' => 'value2']});
    
    # example 5 - use HTTP::Request (with POST as http method) passed in Template::process
    my $tmpl = "[% RINCLUDE http_req_1 %]";
    $tt->process(
        \$tmpl,
        {
            http_req_1 => HTTP::Request->new(
                                                POST => 'http://ya.ru/', 
                                                ['header1' => 'value1','header2' => 'value2'], 
                                                $content
                                             )
        }
    );

example include remote template
    
    # http://example.com/get/template/hello_world => 
    # '<b>Hello, [% name %]!</b><br>[% name = "Boris" %][% RINCLUDE  "http://example.com/.../another" %]'
    # and
    # http://example.com/.../another => 
    # '<b>And goodbye, [% name %]!</b>'
    
    # example
    my $tmpl = "[% RINCLUDE GET 'http://example.com/get/template/hello_world' %]";
    $tt->process(\$tmpl,{name => 'User'});
    
    # returned
    <b>Hello, User!</b><br><b>And goodbye, Boris!</b>

more power example
    
    use Template;
    use Template::Parser::RemoteInclude;
    
    my $tt = Template->new(
         INCLUDE_PATH => '....',
         ....,
         PARSER       => Template::Parser::RemoteInclude->new(
             'Template::Parser' => {
                 ....,
             },
             'AnyEvent::Curl::Multi' => {
                max_concurrency => 10,
                ....,
             }
         ),
         WRAPPER => 'dummy.tt2'
    );    
    
    # where 'dummy.tt2'
    #    [% IF CSS %]
    #        [% FOREACH c = CSS %]
    #            css = [% c %]
    #        [% END %]
    #    [% END %]
    #    ====
    #    [% content %]
    #    ====
    
    # http://example.com/get/template/hello_world => 
    # "[% CSS.push('http://example.com/file.css') %]\nHello, [% name %]!\n"
    
    my $tmpl = "[% SET CSS = [] %][% RINCLUDE GET 'http://example.com/get/template/hello_world' %]";
    $tt->process(\$tmpl,{name => 'User'});
    
    # output:
    #    css = http://example.com/file.css
    #
    #    ====
    #        
    #    Hello, User!
    #        
    #    ====

=head1 METHODS

=head2 new('Template::Parser' => %param1, 'AnyEvent::Curl::Multi' => %param2)

Simple constructor

=cut
sub new {
    my ($class, %param) = @_;
    
    my $self = $class->SUPER::new($param{'Template::Parser'});
    $self->{iparam} = $param{'AnyEvent::Curl::Multi'} || {};
    
    return $self;
}

sub _parse {
    my ($self, $tokens, $info) = @_;
    $self->{ _ERROR } = '';
    
    $self->{aecm} = AnyEvent::Curl::Multi->new(%{$self->{iparam}});
    
    # выгребем все id элементов массива с RINCLUDE и url в качесвте первого аргумента
    my @ids_rinclude = ();
    for (0..$#$tokens) {
        if (
            UNIVERSAL::isa($tokens->[$_],'ARRAY') and
            UNIVERSAL::isa($tokens->[$_]->[2],'ARRAY') and
            $tokens->[$_]->[2]->[1] and
            not ref $tokens->[$_]->[2]->[1] and 
            $tokens->[$_]->[2]->[1] eq 'RINCLUDE'
        ) {
            push @ids_rinclude, $_;
        }
    }
    
    # хэш-связка: id элемента в массиве -> ссылка в памяти
    my $ids_rinclude = {};
    # наполним хэш: ссылка в памяти -> объект запроса
    my %requests = map {
        my $req = $self->_make_request($tokens->[$_]);
        return unless $req; 
        my $addr = refaddr($req);
        $ids_rinclude->{$_} = $addr;  
        ($addr => $req); 
    } @ids_rinclude;
    
    # зарегистрируем запросы в Curl::Multi
    my @handler_cm = map {$self->{aecm}->request($_)} values %requests;
    
    # колбэчимся и в колбэке переопределяем значения в %requests
    $self->{aecm}->reg_cb(response => sub {
        my ($client, $request, $response, $stats) = @_;
        $requests{refaddr($request)} = $response->content;
        #$requests{refaddr($request)} = "[% CSS.push('http://example.com/file.css') %]\nHello, [% name %]!\n";
    });
      
    $self->{aecm}->reg_cb(error => sub {
        my ($client, $request, $errmsg, $stats) = @_;
        $self->debug("error returned RINCLUDE for url: ".$request->uri." - $errmsg") if $self->{ DEBUG };
        $self->error("RINCLUDE for url: ".$request->uri." - $errmsg");
        #$requests{refaddr($request)} = $errmsg;
    });
    
    # поднимаем событие обхода для Curl::Multi
    $self->{timer_w} = AE::timer(0, 0, sub { $self->{aecm}->_perform }) if (@handler_cm and not $self->{timer_w});
    
    # погнали (see AnyEvent::Curl::Multi)
    for my $crawler (@handler_cm) {
         try {
            $crawler->cv->recv;
        } catch {
            $self->debug("error returned RINCLUDE for url: ".$crawler->{req}->uri." - $_") if $self->{ DEBUG };
            $self->error("RINCLUDE for url: ".$crawler->{req}->uri." - $_");
            #$requests{refaddr($crawler->{req})} = $_;
        };
    };
    
    return if $self->error;
    
#    # replace tokens RINCLUDE to simple value
#    for (@ids_rinclude) {
#        $tokens->[$_] = [
#           "'".$ids_rinclude->{$_}."'", # unic name - addr
#           1,
#           $self->split_text($requests{$ids_rinclude->{$_}})
#        ];
#    }

    # extend tokens RINCLUDE to new array values from request
    for (@ids_rinclude) {
        my $parse_upload = $self->split_text($requests{$ids_rinclude->{$_}});
        my $added_len = $#$parse_upload;
        splice(@$tokens, $_, 1, @$parse_upload); 
        $_ += $added_len for @ids_rinclude;
    }
    
    my $cli = delete $self->{aecm};
    undef $cli;
    
    # методично, как тузик тряпку, продожаем обработку токенов, пока не исчерпаем все RINCLUDE, если они пришли в контенте ответов
    if (@ids_rinclude) {
        return $self->_parse($tokens, $info);
    } else {
        delete $self->{__stash};
        return $self->SUPER::_parse($tokens, $info);
    }
}

sub _strip {
    my $text = shift;
    return $text unless $text;
    $text =~ s/(^$1|$1$)//g if $text =~ /^(['"])/;
    return $text;    
}

sub _make_request {
    my $self = shift;
    my $token = shift;
    return unless (UNIVERSAL::isa($token,'ARRAY') and UNIVERSAL::isa($token->[2],'ARRAY'));
    my @token = @{$token->[2]};
    
    # skip RINCLUDE
    splice(@token,0,2);
    
    my $ret = HTTP::Request->new();
    my $is_header = 0; my @headers = ();
    while (@token) {
        my $type = shift @token || '';
        my $val = shift @token || '';
        $val = _strip($val) || '';

        next if ($type eq 'ASSIGN' or $type eq 'COMMA');
        
        if ($type eq 'IDENT') {
            $type = 'LITERAL';
            $val = $self->{__stash}->{$val};
            if (UNIVERSAL::isa($val, 'HTTP::Request')) {
                $self->debug("uri found: ".$val->uri) if $self->{ DEBUG };
                return $val;
            };
        };
                
        if ($val eq 'GET' or $val eq 'POST' or $val eq 'PUT' or $val eq 'DELETE') {
           $ret->method($val); 
        } elsif ($type eq '[') {
            $is_header = 1;
        } elsif ($type eq ']') {
            $is_header = 0;
            while (@headers) {$ret->header(splice(@headers,0,2))}
        } elsif ($type eq 'LITERAL' and $is_header) {
            push @headers, UNIVERSAL::isa($val, 'ARRAY') ? @$val : $val;
        } elsif ($type eq 'LITERAL' and not $is_header) {
            if ($ret->uri) {
                $ret->content($val);
            } else {
                $ret->uri($val);
                $self->debug("uri found: ".$ret->uri) if $self->{ DEBUG }; 
            };
        } else {
            # skip unknown
            next;
        }
    }
    
    return $ret;
}

=head1 SEE ALSO

L<AnyEvent::Curl::Multi>, L<Template>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
