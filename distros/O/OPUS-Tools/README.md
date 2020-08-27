# OpusTools - the Perl package

OpusTools-perl is a collection of tools and scripts to manipulate parallel data collected in [OPUS](http://opus.nlpl.eu/). There are tools for reading, converting and processing the data in various ways. Note that there is also an alterantive Python package called [OpusTools](https://github.com/Helsinki-NLP/OpusTools) that provides similar functionalities but both of these packages do not cover the same kind of tasks even though there is some overlap.

## Installing

```
perl Makefile.pl
make all
make install
```

### Requirements


The following Perl libraries are required

* Module::Install
* Archive::Zip
* DB_File
* HTML::Entities
* Lingua::Sentence
* Ufal::UDPipe
* XML::Parser
* XML::Writer


## Tools and their usage

The package includes a number of tools that can be used on the command-line. 
Tools for reading and processing data:

* **opus-read**: read and filter sentence aligned corpora
* **opus-cat**: read files from zipped OPUS corpus file collections
* **opus-udpipe**: parse OPUS corpora with UDPipe


Tools related to alignment:

* **opus-merge-align**: merge sentence alignment files (delete duplicates)
* **opus-pivoting**: create transitive sentence links via a pivot language
* **opus-pt2dic**: extract a rough bilingual dictionary from SMT phrase-tables
* **opus-pt2dice**: extract a bilingual dictionary with DICE scores
* **opus-split-align**: get alignments per document from a sentence alignment file
* **opus-swap-align**: swap the sentence alignment


Conversion tools:

* **moses2opus**: convert aligned plain text files to OPUS format
* **opus2moses**: extract aligned plain text files from OPUS files
* **tmx2moses**: convert TMX files into aligned plain text files
* **tmx2opus**: convert TMX files into OPUS format
* **xml2opus**: add sentence boundary markup to arbitrary XML files
* **opus2text**: extract plain text from OPUS XML files
* **opus2multi**: make a multiparallel corpus using a pivot language
* **opus-iso639**: convert between ISO639 standards


Admin tools:

* **opus-index**: create CWB indeces from OPUS corpora
* **opus-make-website**: generate corpus websites



### opus-read

Read aligned sentences from OPUS corpora:

```
opus-read [OPTIONS] align-file.xml
```

Command-line options:

```
     -c <thr> ........... set a link threshold <thr>
     -d <dir> ........... set home directory for aligned XML documents
     -h ................. print simple HTML
     -l ................. print links (filter mode)
     -m <max> ........... print max <max> alignments
     -n <regex> ......... get only documents that match the regex
     -N <regex> ......... skip all documents that match the regex
     -o <thr> ........... set a threshold for time overlap (subtitle data)
     -r <release> ....... release (default = latest)
     -s <LangID> ........ require source sentences to match <LangID>
     -t <LangID> ........ require target sentences to match <LangID>
     -S <max> ........... maximum number of source sentence in alignments
     -T <max> ........... maximum number of target sentence in alignments
     -SN <nr> ........... number of source sentence in alignments
     -TN <nr> ........... number of target sentence in alignments
```

"opus-read" is a simple script to read sentence alignments stored in XCES
align format and prints the aligned sentences to STDOUT. It requires
monolingual alignments (ascending order, no crossing links) of sentences
in linked XML files. Linked XML files are specified in the "toDoc" and
<fromDoc> attributes (see below).

```
 <cesAlign version="1.0">
  <linkGrp targType="s" toDoc="source1.xml" fromDoc="target1.xml">
    <link certainty="0.88" xtargets="s1.1 s1.2;s1.1" id="SL1" />
     ....
  <linkGrp targType="s" toDoc="source2.xml" fromDoc="target2.xml">
    <link certainty="0.88" xtargets="s1.1;s1.1" id="SL1" />
```

Several parameters can be set to filter the alignments and to print only
certain types of alignments.

`opus-read` can also be used to filter the XCES alignment files and to
print the remaining links in the same XCES align format. Use the "-l" flag
to enable this mode.

Example usage:

```
     # read sentence alignments and print aligned sentences
     opus-read align-file.xml
     opus-read align-file.xml.gz
     opus-read corpusname/lang-pair
     opus-read -d corpusname lang-pair
     opus-read -d corpusname -s srclang -t trglang

     # print alignments with alignment certainty > LinkThr=0
     opus-read -c 0 align-file.xml

     # print alignments with max 2 source sentences and 3 target sentences
     opus-read -S 2 -T 3 align-file.xml

     # print aligned sentences marked as 'de' (source) and 'en' (target)
     # (this only works if sentences are marked with languages:
     #  for example, in the German XML file: <s lang="de">...</s>)
     opus-read -s de -t en align-file.xml

     # wrap aligned sentences in simple HTML
     opus-read -h align-file.xml

     # print max 10 alignments
     opus-read -m 10 align-file.xml

     # specify home directory of aligned XML files
     opus-read -d /path/to/xml/files align-file.xml

     # print XCES align format of all 1:1 sentence alignments
     opus-read -S 1 -T 1 -l align-file.xml
```


### opus-udpipe

opus-udpipe runs OPUS data through UDPipe and produces OPUS compatible XML.

```
opus-upipe [OPTIONS] < input.xml > output.xml
```

Command-line options:

```
     -l <langid> ......... language ID (ISO639-1)
     -m <modeldir> ....... path to udpipe models
     -v <version> ........ model version
     -D .................. print model dir (and stop)
     -L .................. list supported languages
     -M .................. list UDPipe models
    
```

Option -M can be combined with -D and -L/-l to get various kinds of combined output.



### opus-index

A tool for indexing OPUS data with the Corpus Work Bench (CWB). It extracts sentences, positional attributes (such as POS tags) and structural markup. It also converts sentence alignment information and prepares the vertical format that can be imported by the CWB tools. This tool is mainly for internal use within the OPUS server environment.

Command-line options:

```
       -a lang.... list of aligned languages (optional, space separated)
       -o ........ overwrite existing data (deletes entire data directory!!)
       -y ........ assumes yes (doesn't prompt before deleting data dir!)
       -s ........ skip conversion via recode (used for OO)
       -m dir .... directory for temporary data (otherwise /tmp/BITEXTINDEXER...)
       -i depth .. min depth for finding alignment file (0 otherwise)
       -u pattern  allowed structural patterns
       -p pattern  allowed positional patterns
       -U pattern  disallowed structural patterns
       -P pattern  disallowed positional patterns
       -M ........ skip creating monolingual index files
       -A ........ skip creating alignment files
       -k ........ keep temp file for cwb encoding
       -e enc .... use character encoding enc
       -C ........ convert only (don't run indexing and registring)
```
