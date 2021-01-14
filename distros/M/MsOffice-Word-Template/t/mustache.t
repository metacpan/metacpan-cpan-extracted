use strict;
use warnings;
use MsOffice::Word::Template;
use Test::More;


SKIP: {
  eval "use Template::Mustache; 1"
    or skip "Template::Mustache is not installed";

  my $do_save_results = $ARGV[0] && $ARGV[0] eq 'save';

  (my $dir = $0) =~ s[mustache.t$][];
  $dir ||= ".";
  my $template_file = "$dir/etc/mustache_template.docx";

  my $template = MsOffice::Word::Template->new(
    docx      => $template_file,
    start_tag => "{{",
    end_tag   => "}}",
    engine    => sub {
      my ($self, $vars) = @_;

      # at the first invocation, create a Mustache compiled template and store it in the stash.
      # Further invocations will just reuse the object in stash.
      my $stash            = $self->{engine_stash} //= {};
      $stash->{mustache} //= Template::Mustache->new(
        template => $self->{template_text},
        @{$self->engine_args},   # for ex. partials, partial_path, context
                                 # -- see L<Template::Mustache> documentation
       );

      # generate new XML by invoking the template on $vars
      my $new_XML = $stash->{mustache}->render($vars);

      return $new_XML;
      },
   );

  my %data = (
    foo => 'FOFOLLE',
    bar => 'WHISKY & <GIN>',
    list => [ {name => 'toto',   value => 123},
              {name => 'blublu', value => 456},
              {name => 'zorb',   value => 987},
             ],
  );
  my $new_doc = $template->process(\%data);
  my $xml = $new_doc->contents;

  like $xml, qr[Hello, </w:t></w:r><w:r><w:t>FOFOLLE</w:t></w:r>], "Foo";
  like $xml, qr[toto</w:t></w:r></w:p></w:tc>], "toto in first table row";

  $new_doc->save_as("mustache_result.docx") if $do_save_results;
}


done_testing;
