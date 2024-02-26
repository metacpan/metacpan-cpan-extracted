all: generate

clean:
	$(RM) -Rf lib/RDF/Cowl/Lib/Gen
	$(RM) -Rf ffi/*.gen.c
	$(RM) -Rf ffi/_build/

# NOTE: Set RDF_COWL_GEN_GLOBAL=1 to create helper file
generate: clean
	perl ./maint/process-api.pl generate
