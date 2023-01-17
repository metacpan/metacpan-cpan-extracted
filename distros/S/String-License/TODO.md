# pending tasks and loose ideas

## flexible patterns

* test each pattern (not only the default combined pattern)
* add option to generate either minimal or maximal pattern
  * minimal: shortest coverage decisive of one or more objects.
  * distinct: shortest coverage to disambiguate from unrelated objects
    and objects it depends on,
    and large enough for dependent objects to disambiguate from it.
  * successive: minimal or distinct + surplus up until next ambiguation point
  * maximal: full coverage


## misc

  * Support adding custom patterns
    to enable frontend to to implement extensibility similar to license-reconsile
    <https://lists.debian.org/87efl0kvzu.fsf@hands.com>
  * Support smarter processing:
    * Gather statistics on objects detected,
      to enable a frontend tool to emit progress during long-running scans
  * Detect non-commercial license.
    (?i:(?:\w{4}|\W(?:[^oO]\w|\w[^rR]|[^aA]\w\w|\w[^nN]\w|\w\w[^dD])) non[-_ ]commercial)
  * Detect bugroff license <http://tunes.org/legalese/bugroff.html>


## See also

  * Compare against competitors
    + ripper
    + https://salsa.debian.org/stuart/package-license-checker
    + r-base /share/licenses/license.db
    + license-reconcile
    + https://wiki.debian.org/CopyrightReviewTools
    + https://docs.clearlydefined.io/clearly#licensed
    + http://copyfree.org/standard/licenses
    + https://wiki.debian.org/DFSGLicenses
    + http://voag.linkedmodel.org/2.0/doc/2015/REFDATA_voag-licenses-v2.0.html
    + https://github.com/hierynomus/license-gradle-plugin
    + ruby-licensee - http://ben.balter.com/licensee/
    + flict - https://github.com/vinland-technology/flict


## misc

  * Optimize:
    + Support detection reversion, and first scan for grants then licenses - reverting embedded grants
  * Test against challenging projects
    + ghostpdl
    + chromium
    + fpc
    + lazarus
    + boost
    + picolibc <https://keithp.com/cgit/picolibc.git/>

  * Support smarter interogation
    * Provide methods to inspect position of detected objects
      to enable frontends to e.g. visualize using String::Tagged or Text::Locus

  * Detect quality issues
    + incomplete: fractions of license fullref, but no complete fullref
    + alien: license label but no license name
    + uncertain: license ref and more unknown text in same sentence/paragraph/section
    + buried: license not at top of file
    + unstructured: license not at ideal place of data structure
      (e.g. in content or comment of html)
    + imperfect: license ref not following format documented in license fulltext

  * use nano-style configurable wordchars/punct/brackets/matchbrackets chars and quotestr regex
    e.g. to determine sentences
    (see "paragraphs" and "justify" in "man nanorc")
