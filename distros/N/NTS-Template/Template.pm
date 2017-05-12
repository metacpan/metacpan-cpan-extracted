# O NTS::Template foi baseado na estrutura de programacao
# do Template Toolkit
# By: Udlei Nattis <unattis@nattis.com>

package NTS::Template;

use strict;
no warnings;
our $VERSION = '2.1';

my (%my,@string);
my $func = {
    # Funcao printf
    PRINTF  => "my \$PRINTF = sub { my (\$x,\$y) = \@_; printf(\$x,\$y); };",

    # Funcao copiada do CGI::Util
    ESCAPE  => "my \$ESCAPE = sub { 
        my (\$toenc) = shift; 
        return undef unless defined (\$toenc);
        \$toenc = pack(\"C*\", unpack(\"C*\", \$toenc)); 
        \$toenc=~s/([^a-zA-Z0-9_.-])/uc sprintf(\"%%%02x\",ord(\$1))/eg;
        print(\$toenc); };",

    # Funcao copiada do CGI::Util
    UNESCAPE    => "my \$UNESCAPE = sub {
        my \$todec = shift;
        return undef unless defined(\$todec);
        \$todec =~ tr/+/ /;
        \$todec =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
        defined(\$1)? chr hex(\$1) : utf8_chr(hex($\2))/ge;
        print(\$todec); };",
};

# Atalho
sub view_templ {
    my($templ_dir,$templ_file,$templ_vars,$templ_extra) = @_;
    
    my $templ = NTS::Template->new();
    my $r = $templ->process({ templ_dir => $templ_dir, templ_file => $templ_file, templ_vars => $templ_vars,
        templ_extra => $templ_extra });

    return $r;
}

# Cria modulo do template
sub new {
    my ($class,$vars) = @_;
    my $self = {};

    bless $self, ref $class || $class || "NTS::Template";

    return $self;
}

# Processa arquivo
sub process {
    my ($self,$vars) = @_;
    my ($data,$file,$_r);
    
    # Arquivo
    $file = $vars->{templ_dir}."/".$vars->{templ_file};
    
    # Executa parse
    $data .= $self->parse($self->load($file),$vars->{templ_vars},$vars->{templ_dir});

    # Retira quebra de linha
    $data =~ s/\s+|\t+/ /g if ($vars->{templ_extra}->{nospaces});

    my $my;
    foreach (keys %my) { 
        # Variavel com conteudo
        if (defined $vars->{templ_vars}->{$_}) { $my .= "my \$$_ = \$vars->{templ_vars}->{$_};\n"; }
       
        # Verifica se existe funcao
        elsif ($func->{$_}) { $my .= $func->{$_}."\n"; }
       
        # Variavel sem conteudo
        else { $my .= "my \$$_;\n"; };
    }

    $data = $my.$data;

    # Saida para variavel
    if (defined $vars->{templ_extra}->{oreturn}) {
        $data =~ s/[^s]print\(|[^s]printf\(/\$_r .= sprintf(/g;
    }
    
    # Verifica se deve alterar saida dos dados
    elsif ($ENV{'MOD_PERL'}) {
        $data =~ s/[^s]print\(/Apache->request->print(/g;
        $data =~ s/[^s]printf\(/Apache->request->printf(/g;
        Apache->request->print($data."\n") if $vars->{templ_extra}->{source};
    }

    # Printa sources
    elsif ($vars->{templ_extra}->{source}) {
        print($data."\n");
    }

#    print $data;
#    Apache->request->print($data);
    $_r = eval $data;
    if ($@) {
        if ($ENV{'MOD_PERL'}) {
            Apache->request->print($@);
        } else {
            print $@."\n";
        }
    }

    # Altera saida do source
    $_r = $data."\n".$_r
        if ($vars->{templ_extra}->{source} && $vars->{templ_extra}->{oreturn});

    return $_r if $vars->{templ_extra}->{oreturn};
    return 1;
}

# Abre arquivo
sub load {
    my ($self,$file) = @_;
    my ($data);
    
    # Printa todo o conteudo de uma vez
    local $/;

    if (open(FH,"<".$file)) { 
        $data = <FH>;
        close(FH);
        return $data;
    }

    # Termina com erro
    else { die "Can't open file $file: $!\n"; }
}

sub parse {
    my ($self,$data,$templ_vars,$templ_dir) = @_;
    
    # Adiciona \ em caracteres nao permitidos
    my $p = 0;
    my ($ndata,$i,$j);
    
    # Recupera condicoes
    while ($data =~ s/(.*?)?(?:\[\%\s?(.*?)\s?\%\])//sx) {
        
        # String padrao
        $ndata .= "print(\"".AddSlashes($1)."\"); ";

        my ($n,$c,$nc,$l,$tp,$fc);
        $l = ($2 =~ /^#/) ? "" : $2;
        
        # Verifica qual o tipo de condicao
        if ($l eq "ELSE") { $n = " } else { "; }
        elsif ($l eq "END" || $l eq "/IF" || $l eq "/FOREACH") { $n = " } "; }
       
        # include
        elsif ($l =~ /^INCLUDE\s+(\-[a-z]+)?\s?(.*)/) { #(\-[a-z]+)?\s+?([\w\.\/]+)/) {
            $i = $1; $j = $2;
           
            # Include em variavel
            if ($templ_vars->{$j} =~ /^(.*)\/([\w\-\.]+)$/) {
                $ndata .= $self->parse($self->load($1."/".$2),$templ_vars,$templ_dir)
                    if (!$i || ($i eq "-f" && -f $1."/".$2)); }

            # Include padrao
            else {
                $ndata .= $self->parse($self->load($templ_dir."/".$j),$templ_vars,$templ_dir)
                    if (!$i || ($i eq "-f" && -f $templ_dir."/".$j)); }
        }
       
        elsif ($l =~ /^IF\s?(.*)/) { $c = $1; $n = "if "; }
        
        elsif ($l =~ /^UNLESS\s?(.*)/) { $c = $1; $n = "unless "; }
        
        elsif ($l =~ /^FOREACH\s+(\w+)\s?=\s?(.*)/) { 
            # $tp (type) verifica tipo de $c e adiciona ele em keys %{}, @{} ou outra forma
            # quando necessario
            $tp = $2; 
            $c = $2; $n = "foreach \$$1 "; $my{$1} = 1; }
            
        elsif ($l =~ /^FOR\s?(.*)/) { $c = $1; $n = "for "; }
        
        elsif ($l =~ /^(ELSIF|^ELSEIF)\s?(.*)/) { $c = $2; $n = " } elsif "; }
       
        # Funcoes
        elsif ($l =~ /^\&(\w+)\((.*)\)/) {
            $c = $2;
            $nc = 1;

            # $fc = function
            $fc = $1;
            $my{$1} = 1;
        }
       
        else { 
            # $nc = no condition
            $nc = 1; 
            $c = $l; }

        # Monta condicao
        if ($c) { 

            # Recupera strings
            my (@string,$s);
            
            $s = 0;
            while ($c =~ s/([\-a-z]{1,2}?\s)?(\".*?[^\\]\")|([\-a-z]{1,2}?\s)?(\/.*?\/)/ .$s/) { 
          
                if ($4) { $string[$s] = $4; }
                elsif ($1) { $string[$s] = $1."\"".$templ_dir."/\".".$2; }
                else { $string[$s] = $2; }
               
                $s++; 
            }

            # Trata condicoes e variaveis
            my @n;
            
            #while ($c =~ s/\s?([^\(\)=!&<>\s]+)(\s+)?([\(\)=!&<>]{1,2})?//) {
            while ($c =~ s/\s?(^[\!])?([^\;\(\)=!&<>\s\%\,\~]+)(\s+)?([\~\,\;\(\)=!&<>\+\%\-\.\*\/]{1,2})?//) {
                my $i = $2;
                my $j = $4;
                my $k = $1;

                # Altera tudo para eq e ne
                if ($j eq "==") { $j = "eq"; }
                elsif ($j eq "!=") { $j = "ne"; }

               
                # Volta para == caso seja igual a 0
                if ($i eq "0") { 
                    if ($n[$#n] =~ /\s+?eq\s+?/) { $n[$#n] = " == "; }
                    elsif ($n[$#n] =~ /\s+?ne\s+?/) { $n[$#n] = " != "; }
                }
                
                # Recupera strings
                if ($i =~ /^\.(\d+)/) {
                    $i = $1;                  
                    push(@n,$string[$i]); }

                else { 
                    push(@n,$k.&parse_cond($i,$j)); }

                # Adiciona condicao
                if ($j) { 
                    push(@n," $j "); }
            }
           
            # Recupera variavel
            $i = join("",@n);
            
            # Var simples
            if (defined $nc) {
                # Verifica quando 'e para printar variavel
                if (!$#n && $i =~ /\w$|}$/) {
                    $n .= "print($i); "; }
                
                # Verifica se esta dentro de uma funcao
                elsif (defined $fc) {
                    $n .= "&\$".$fc."(".$i."); ";
                }
                
                else { $n .= $i."; "; }
                
            } 

            # Condicao
            else { 

                # Verifica se precisa tratar tipo
                if (defined $tp) {
                    $tp =~ s/\./}->{/g;
              
                    # Verifica se 'e array
                    $j = ref $templ_vars->{$tp};
                    if ($j eq "ARRAY") { $i = "\@{$i}"; }
                
                    # Verifica se 'e hash
                    elsif ($j eq "HASH") { $i = "keys \%{$i}"; }

                    # Else
                    else { $i = "\@{$i}"; }
               
                    undef $tp;
                }
                
                $n .= "($i) { "; }
        }

        $ndata .= $n; 
    }

    $ndata .= "print(\"".AddSlashes($data)."\"); " if $data;

    return $ndata;
}

# Parseia condicoes
sub parse_cond {
    my ($i,$j) = @_;
  
    # Verifica AND e OR
    if ($i eq "AND") { return " && "; }
    elsif ($i eq "OR") { return " || "; }

    # Valor numerico
    elsif ($i =~ /^(\d+)$/) { return "\'".$1."\'"; }

    # Trata variavel simples
    elsif ($i =~ /^(\w+)([\+\-]{2})?$/) { $my{$1} = 1; return "\$$1$2"; }

    # Variavel estilo hash
    elsif ($i =~ /^\w+[\.]{1}\w+/) {
    
        # Separa pela virgula para tratar
        my @r;
        while ($i =~ s/(\w+)([\+\-]{2})?//sx) {
            if (@r) { push(@r,"{$1}$2"); }
            else { push(@r,"\$$1"); $my{$1} = 1; }
        }
    
        return join("->",@r);
    }

    else {
        return $i; }
}

# Adiciona barras invertidas
sub AddSlashes {
    my($str,$oreturn) = @_;     

    $str =~ s/\%/%%/g if ($oreturn);
    #$str =~ s/\\/\\\\/g;

    $str =~ s/([\"\#\@\$\\])/\\$1/g;

    return $str;
}

1;

__END__

=head1 NAME

NTS::Template - Fast and small template system

=head1 Description

Formerly Ananke::Template, this Template System is based in Template ToolKit. Very small compared with Template Toolkit, and 100% compatible with mod_perl 2.

Speedy:

    $ cd /proc ; grep name cpuinfo
    model name      : AMD Athlon(tm) XP 1700+

    $ ./bench_templ
    Benchmark: timing 5000 iterations of NTS::Template, Template ToolKit...
    NTS::Template:  9 wallclock secs ( 9.48 usr +  0.11 sys =  9.59 CPU) @ 521.38/s (n=5000)
    Template ToolKit: 25 wallclock secs (24.84 usr +  0.16 sys = 25.00 CPU) @ 200.00/s (n=5000)

Memory:

    $ ./GTop -m NTS::Template

    NTS::Template
          Size     Shared       Diff
       2564096    1642496     114688 (bytes)

    $ ./GTop -m Template
    
    Template
          Size     Shared       Diff
       3960832    1683456    1470464 (bytes)

=head1 SYNOPSIS

no comment

=head1 TO DO

no comment

=head1 DIRECTIVE

=head2 IF, ELSIF OR ELSEIF, UNLESS

try:

    $vars->{test1} = "ok";
    $vars->{test2}->{test2} = "ok";
    $vars->{test3} = 1;

    [% IF test1 %] ok, test1 [% END %]
    [% IF test2.test2 %] ok, test2.test2 [% END %]
    [% IF test1 == test2.test2 %] ok, test1 == test2.test2 [% END %]
    [% IF test1 == "ok" %] ok, test1 == "ok" [% END %]
    [% IF test3 == 1 %] ok, test3 [% END %]
    [% IF test1 AND test2.test2 AND test3 %] ok, test1 AND test2.test2 AND test3 [% END %]
    [% IF test1 OR test3 %] ok, test1 OR test3 [% END %]
    [% IF test1 == test3 %] ok, test1 == test3 [% ELSE %] fail [% END %]
    [% IF test1 == test3 %] ok, test1 == test3 
    [% IF test1 != "fail" %] ok, test1 != "ok" [% ELSE %] fail [% END %]
    [% IF test2.test2 != "fail" %] ok, test2.test2 != "ok" [% ELSE %] fail [% END %]

    [% IF test1 == test3 %] ok, test1 == test3
    [% ELSIF test2.test2 == test3 %] ok, test2.test2 == test3 
    [% ELSE %] fail [% END %]

    [% UNLESS test1 == "fail" %] fail, test == "fail" [% ELSE %] ok [% END %]

return:

    ok, test1 
    ok, test2.test2 
    ok, test1 == test2.test2 
    ok, test1 == "ok" 
    ok, test3 
    ok, test1 AND test2.test2 AND test3 
    ok, test1 OR test3 
    fail
    ok, test1 != "ok" 
    ok, test2.test2 != "ok" 
    fail
    fail, test == "fail" 

=head2 FOREACH

Repeat the enclosed FOREACH ... END block for each value in the list.

    [% FOREACH variable = list %]                 
        content... 
        [% variable %]
    [% END %]

    # or

    [% FOREACH i = list_chn_grp %]
        [% count++ %]
        [% IF count % 2 %] [% bgcolor = "#FFFFFF" %]
        [% ELSE %] [% bgcolor = "#EEEEEE" %]
        [% END %]
    
        [% i.bgcolor %]
    [% END %]

=head2 FOR

    [% FOR i=1;i<=12;i++ %]
        [% i=1 %]
    [% END %]

=head2 VARIABLES

    [% var = 'text' %]
    [% var %]

=head2 &PRINTF

    [% var = 2 %]
    [% &PRINTF('%02d',var) %]

=head2 &ESCAPE/&UNESCAPE

    [% var = "http://www.nattis.com.br?a=b&c=d&e=f" %]
    [% &ESCAPE(var,'') %]
    [% &UNESCAPE(var,'') %]

=head1 Authors

=over

=item

    Udlei Nattis E<lt>unattis (at) nattis.comE<gt>
    http://www.nattis.com

=back

=cut
