use TOBYINK::Pod::HTML;
print "TOBYINK::Pod::HTML"->new(code_highlighting => 1, pretty => 1)->file_to_html(__FILE__);

__END__

=head1 NAME

RDF Syntax Highlighting Examples

=head1 EXAMPLES

Here is some Turtle for syntax highlighting...

=for highlighter language=Turtle

   @prefix foaf: <http://xmlns.com/foaf/0.1/>.
   
   <http://tobyinkster.co.uk/#i>
      a foaf:Person;
      foaf:name "Toby Inkster".

And here's how you might query it using SPARQL...

=for highlighter language=SPARQL

   PREFIX foaf: <http://xmlns.com/foaf/0.1/>
   SELECT ?name
   WHERE {
      <http://tobyinkster.co.uk/#i> foaf:name ?name.
   }

And this is the result set you might get:

=for highlighter language=JSON

   {
      "head": { "vars": ["name"] },
      "results": { 
         "bindings": [
            {
               "title": { "type": "literal", "value": "Toby Inkster" }
            }
         ]
      }
   }
