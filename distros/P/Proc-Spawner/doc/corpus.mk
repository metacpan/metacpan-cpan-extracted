# ---------------------------------------------------------------------------------------------------------------------
# Corpus analysis (doc/corpus.mk, copied in by Makefile.PL; doc/test-pools.md, section 0).  Not part of building,
# installing or `make test`.  Linux; the runs need root, no network (unshare -n), dash and bash.  `make corpus-help`.
# Work files go to CORPUS; the targets marked "(record)" rewrite the shipped file they name.
CORPUS = corpus-work
CORPORA = $(CORPUS)/corpora
CT = doc/large-subset/tools
CJ = 4
CBASE = /runcompare
CENV = -env tmp,random,mtime -base $(CBASE)
CENV3 = -env cowroot,tmp,random,mtime -base $(CBASE) $(CCALLS)
OLDSCAN =
SCCACHE = $(CORPUS)/sc-cache.jsonl
CPROV = doc/large-subset/large-subset-provenance.tsv
CSTEP3 = doc/large-subset/tools/large-subset-step3.tsv
CAI = doc/large-subset/tools/large-subset-ai-classes.tsv
CSAMPLES = $(CORPUS)/samples.jsonl $(CORPUS)/samples.tsv
CRUN = unshare -n $(PERL) $(CT)/large-subset-runcompare.pl
# X84 (post-0.13): a stand-in, for its runs alone, for each program a snippet calls that is not on the runner's list (step 3,
# its races, and the variants fail, output, mtime with their base runs sbase, sbase2)
CCALLS = -calls $(CPROV)
CROOT = test "`id -u`" = 0 || { echo "$@: run as root (it makes the users rc0..rc3 and mounts)"; exit 1; }
CCLEAN = for u in rc0 rc1 rc2 rc3 rc9; do id $$u >/dev/null 2>&1 && find /tmp /var/tmp /dev/shm -xdev -mindepth 1 -maxdepth 1 -user $$u -exec rm -rf {} + ; done; true

#: corpus-help         this list
corpus-help :
	@$(PERL) -ne "print substr(\$$_, 3) if /^#: /" $(FIRST_MAKEFILE)

#: corpora             the sources at their pinned commits, and the book (about 1 minute; git, curl, pdftotext)
corpora : $(CORPORA)/.done
$(CORPORA)/.done :
	$(PERL) $(CT)/large-subset-corpora.pl $(CORPORA)

#: corpus-pool-a-check pool A (the base parser's corpus tests) against the sources
corpus-pool-a-check : $(CORPORA)/.done
	$(PERL) doc/parsers/tools/prov.pl $(CORPORA) --check t/parser/shell-subset-corpus-tests.pl
#: corpus-pool-a       pool A's texts again from the recorded grouping, into CORPUS/pool (not over t/: 47 results
#:                     there were changed by hand since)
corpus-pool-a :
	mkdir -p $(CORPUS)/pool && cp doc/parsers/tools/groups.tsv $(CORPUS)/pool/ && d=`pwd` && cd $(CORPUS)/pool && $(PERL) $$d/doc/parsers/tools/gentests.pl

#: corpus-samples      pool B: every sample of the sources (CORPUS/samples.jsonl)
corpus-samples : $(CORPUS)/samples.jsonl
$(CORPUS)/samples.jsonl : $(CORPORA)/.done
	$(PERL) $(CT)/large-subset-extract.pl $(CORPORA) $@.new && mv $@.new $@

#: corpus-scan         both parsers, dash -n, bash -n and ShellCheck on every sample (25 minutes; pip install
#:                     shellcheck-py==0.11.0.1); with OLDSCAN=FILE a stored scan reparsed instead (15 seconds; give
#:                     its ShellCheck cache as SCCACHE=FILE)
corpus-scan : $(CORPUS)/large-scan.jsonl
$(CORPUS)/large-scan.jsonl : $(CORPUS)/samples.jsonl
	if test -n "$(OLDSCAN)"; then $(PERL) -Ilib $(CT)/large-subset-reparse.pl $(CORPUS)/samples.jsonl $(OLDSCAN) > $@.new; \
	else $(PERL) -Ilib $(CT)/large-subset-scan.pl $(CORPUS)/samples.jsonl > $@.new; fi && mv $@.new $@

#: corpus-parse        the parse results (large-subset-state.md): CORPUS/samples.tsv, CORPUS/parse.txt
corpus-parse : $(CORPUS)/samples.tsv
	@cat $(CORPUS)/parse.txt
$(CORPUS)/samples.tsv : $(CORPUS)/large-scan.jsonl
	$(PERL) $(CT)/large-subset-drops.pl $(CORPUS)/samples.jsonl $(CORPUS)/drops.tsv
	$(PERL) $(CT)/large-subset-yardsticks.pl -v -c $(SCCACHE) -o $@.new $(CORPUS)/samples.jsonl $(CORPUS)/large-scan.jsonl $(CORPUS)/drops.tsv > $(CORPUS)/parse.txt && mv $@.new $@

#: corpus-digest       the digest the parse results depend on (unchanged: the parse results hold; large-subset-state.md, 3)
corpus-digest :
	@cat lib/Proc/ShellSubset.pm lib/Proc/ShellSubset/*.pm $(CT)/large-subset-extract.pl $(CT)/large-subset-scan.pl \
	  $(CT)/large-subset-drops.pl $(CT)/large-subset-features.pl $(CT)/large-subset-yardsticks.pl \
	  $(CT)/large-subset-verdicts.txt $(CT)/large-subset-noise.txt | sha256sum

#: corpus-shells       (record) t/parser/large-subset-shells.tsv: the shells' verdict on every parser test
corpus-shells :
	$(PERL) $(CT)/large-subset-features.pl -n t/parser/large-subset-tests.pl t/parser/shell-subset-tests.pl \
	  t/parser/shell-subset-corpus-tests.pl > t/parser/large-subset-shells.tsv.new && mv t/parser/large-subset-shells.tsv.new t/parser/large-subset-shells.tsv

#: corpus-provenance   (record) large-subset-provenance.tsv: every sample's level (large-subset-environment.md;
#:                     8 seconds), and large-subset-step3.tsv (step 3, section 12); the tables of its sections 1
#:                     and 3 in CORPUS/levels.txt; the samples classified by Claude reading them (AI-...) from large-subset-ai-classes.tsv
corpus-provenance : $(CORPUS)/samples.tsv
	$(PERL) -Ilib $(CT)/large-subset-blocks.pl -e $(CPROV) -p $(CSTEP3) -ai $(CAI) -s $(CORPUS)/levels.tsv -o $(CORPUS)/blocks.jsonl $(CSAMPLES) > $(CORPUS)/levels.txt

#: corpus-run          (root) the behaviour run: every sample in dash, bash --posix and ShellSpawn (55 minutes; restartable)
corpus-run : $(CORPUS)/run/.done
$(CORPUS)/run/.done : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	$(CRUN) -j $(CJ) $(CENV) $(CSAMPLES) $(CORPUS)/run && touch $@
#: corpus-rejected    (root) the snippets the large parser rejects, run in dash and bash alone in the base run's
#:                     environment (minutes), compared (record large-subset-rejected.tsv; README.md, the rejected snippets)
corpus-rejected : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	$(PERL) $(CT)/large-subset-rejected.pl -prepare $(CORPUS)
	$(CRUN) -j $(CJ) $(CENV) -shells dash,bash -only @$(CORPUS)/rejected.ids $(CORPUS)/samples.jsonl $(CORPUS)/rejected-samples.tsv $(CORPUS)/rejected
	$(PERL) $(CT)/large-subset-rejected.pl -o $(CT)/large-subset-rejected.tsv $(CORPUS)/samples.tsv $(CORPUS)/samples.jsonl $(CORPUS)/rejected
#: corpus-rejected-envs (root; after corpus-rejected) the work list's candidates (large-subset-rejected-setups.jsonl,
#:                     example environments made by reading them) run in dash and bash in each environment, compared over
#:                     all of them with the base run (record large-subset-rejected-envs.tsv; a minute)
corpus-rejected-envs : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	$(PERL) $(CT)/large-subset-rejected.pl -prepare $(CORPUS)
	$(PERL) $(CT)/large-subset-rejected.pl -split $(CT)/large-subset-rejected-setups.jsonl $(CORPUS)
	for f in $(CORPUS)/rejected-setup-*.jsonl; do k=$${f##*-}; k=$${k%.jsonl}; \
	  $(CRUN) -j $(CJ) $(CENV) -shells dash,bash -setup $$f -only @$(CORPUS)/rejected-envs.ids $(CORPUS)/samples.jsonl $(CORPUS)/rejected-samples.tsv $(CORPUS)/rejected-s$$k || exit 1; done
	$(PERL) $(CT)/large-subset-rejected.pl -o $(CT)/large-subset-rejected-envs.tsv -envs $(CT)/large-subset-rejected-setups.jsonl $(CORPUS)/samples.tsv $(CORPUS)/samples.jsonl $(CORPUS)/rejected $(CORPUS)/rejected-s[0-9]*
#: corpus-qrun         (root) ShellSpawn alone, its calls and builtins logged (55 minutes; restartable)
corpus-qrun : $(CORPUS)/q/.done
$(CORPUS)/q/.done : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	$(CRUN) -q -j $(CJ) $(CENV) $(CSAMPLES) $(CORPUS)/q && touch $@
#: corpus-calls       (record) the column CALLS of large-subset-provenance.tsv marked from the run, per shell (A23 (c))
corpus-calls : $(CORPUS)/run/.done
	$(PERL) $(CT)/large-subset-calls.pl $(CPROV) $(CORPUS)/run

#: corpus-runreport    (record) large-subset-run-differences.tsv; the tables (large-subset-state.md, 7) in CORPUS
corpus-runreport : $(CORPUS)/run/.done $(CORPUS)/q/.done
	$(PERL) $(CT)/large-subset-runreport.pl -q $(CORPUS)/q -known $(CT)/large-subset-match-known.tsv -l $(CT)/large-subset-run-differences.tsv $(CORPUS)/run > $(CORPUS)/runreport.txt
	$(PERL) $(CT)/large-subset-runreport.pl -x -q $(CORPUS)/q -known $(CT)/large-subset-match-known.tsv $(CORPUS)/run > $(CORPUS)/runreport-x.txt
#: corpus-threeway     (root; record) large-subset-threeway-db.jsonl, -differences.tsv: each call, three ways
corpus-threeway : $(CORPUS)/q/.done
	@$(CROOT)
	unshare -n $(PERL) $(CT)/large-subset-threeway.pl -l $(CT)/large-subset-threeway-differences.tsv \
	  -db $(CT)/large-subset-threeway-db.jsonl $(CORPUS)/q > $(CORPUS)/threeway.txt
#: corpus-builtins     (root; record) large-subset-builtins-differences.tsv: each builtin call (45 minutes)
corpus-builtins : $(CORPUS)/q/.done
	@$(CROOT)
	unshare -n $(PERL) $(CT)/large-subset-builtins.pl -l $(CT)/large-subset-builtins-differences.tsv \
	  -db $(CORPUS)/builtins.jsonl $(CORPUS)/q > $(CORPUS)/builtins.txt

#: corpus-env-variants (root; record) large-subset-env-variants.tsv: the environment varied, each variant on the
#:                     samples of its code, against two base runs (large-subset-environment.md, 9; hours); each
#:                     sample runs with the worker of its base run (directory BASE/wK, user rcK: X66)
CVARIANTS = posix:echo utf8:locale sigpipe:pipeline noproc:devfd tmp:path-tmp random:path-random \
  private:path-home,path-mnt,path-var dev:path-dev
CSTANDINS = fail:prog-status output:prog-output mtime:time
corpus-env-variants : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	mkdir -p $(CORPUS)/env && rm -f $(CORPUS)/env/variants.tsv && \
	for g in base sbase; do \
	  if test $$g = base; then vs="$(CVARIANTS)"; else vs="$(CSTANDINS)"; fi; codes=""; \
	  for v in $$vs; do codes="$$codes `echo $$v | cut -d: -f2 | tr , ' '`"; done; \
	  sc=; test $$g = sbase && sc="$(CCALLS)"; \
	  $(PERL) $(CT)/large-subset-ids.pl $(CPROV) $$codes > $(CORPUS)/env/ids-$$g.txt; \
	  for r in $$g $${g}2; do w=; test $$r = $$g || w="-workers-from $(CORPUS)/env/$$g"; \
	    $(CCLEAN); $(CRUN) -j $(CJ) -base $(CBASE) $$sc $$w -only @$(CORPUS)/env/ids-$$g.txt $(CSAMPLES) $(CORPUS)/env/$$r || exit 1; done; \
	  for v in $$vs; do n=`echo $$v | cut -d: -f1`; c=`echo $$v | cut -d: -f2 | tr , ' '`; \
	    $(PERL) $(CT)/large-subset-ids.pl $(CPROV) $$c > $(CORPUS)/env/ids-$$n.txt; $(CCLEAN); \
	    $(CRUN) -j $(CJ) -base $(CBASE) $$sc -env $$n -workers-from $(CORPUS)/env/$$g -only @$(CORPUS)/env/ids-$$n.txt $(CSAMPLES) $(CORPUS)/env/v-$$n || exit 1; \
	    $(PERL) $(CT)/large-subset-runreport.pl -b $(CORPUS)/env/$$g -bl $(CORPUS)/env/variants.tsv -tag $$n \
	      -noise $(CORPUS)/env/$${g}2 $(CORPUS)/env/v-$$n > $(CORPUS)/env/cmp-$$n.txt || exit 1; done; \
	done && mv $(CORPUS)/env/variants.tsv $(CT)/large-subset-env-variants.tsv

#: corpus-step2        (root) step 2 (large-subset-environment.md, 10): each undecided sample's exact dependences,
#:                     example setups, and runs in them (35 minutes; restartable)
corpus-step2 : $(CORPUS)/step2/.done
$(CORPUS)/step2/.done : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	mkdir -p $(CORPUS)/step2
	$(PERL) -Ilib $(CT)/large-subset-blocks.pl -d $(CORPUS)/step2/deps.jsonl $(CSAMPLES) > /dev/null
	$(PERL) -Ilib $(CT)/large-subset-setups.pl -all -full 2 -one $(CORPUS)/step2/deps.jsonl $(CORPUS)/step2/setup
	grep -v '^#' $(CORPUS)/step2/setup-samples.tsv | cut -f1 > $(CORPUS)/step2/setup.ids
	for r in base base2; do $(CRUN) $(CENV) -only @$(CORPUS)/step2/setup.ids $(CSAMPLES) $(CORPUS)/step2/$$r || exit 1; done
	k=1; while test -e $(CORPUS)/step2/setup-$$k.jsonl; do \
	  $(CRUN) $(CENV) -setup $(CORPUS)/step2/setup-$$k.jsonl $(CSAMPLES) $(CORPUS)/step2/s$$k || exit 1; k=`expr $$k + 1`; done
	touch $@

#: corpus-step3        (root) step 2 for step 3's control class (large-subset-environment.md, 12): their exact
#:                     dependences, setups (absolute names, the programs' answers, stand-ins) and runs in them,
#:                     each run in a root of its own (-env cowroot; about an hour; restartable); the match over
#:                     them (records large-subset-env-control.tsv, large-subset-env-control-calls.jsonl; the report in
#:                     CORPUS/step3/match.txt)
corpus-step3 : $(CORPUS)/step3/.done
$(CORPUS)/step3/.done : $(CORPUS)/samples.tsv pure_all
	@$(CROOT)
	mkdir -p $(CORPUS)/step3
	$(PERL) -Ilib $(CT)/large-subset-blocks.pl -d $(CORPUS)/step3/deps.jsonl $(CSAMPLES) > /dev/null
	$(PERL) -Ilib $(CT)/large-subset-setups.pl -all -full 2 -one -step3 $(CSTEP3) $(CORPUS)/step3/deps.jsonl $(CORPUS)/step3/setup
	for r in base base2; do $(CRUN) $(CENV3) -setup $(CORPUS)/step3/setup-0.jsonl $(CSAMPLES) $(CORPUS)/step3/$$r || exit 1; done
	k=1; while test -e $(CORPUS)/step3/setup-$$k.jsonl; do \
	  $(CRUN) $(CENV3) -setup $(CORPUS)/step3/setup-$$k.jsonl $(CSAMPLES) $(CORPUS)/step3/s$$k || exit 1; k=`expr $$k + 1`; done
	R="-run base=$(CORPUS)/step3/base -run base2=$(CORPUS)/step3/base2"; Q="-q base=$(CORPUS)/step3/qbase -q base2=$(CORPUS)/step3/qbase"; \
	k=1; while test -d $(CORPUS)/step3/s$$k; do R="$$R -run s$$k=$(CORPUS)/step3/s$$k"; Q="$$Q -q s$$k=$(CORPUS)/step3/qs$$k"; k=`expr $$k + 1`; done; \
	P="-step3 -prov $(CPROV) -setups $(CORPUS)/step3/setup-samples.tsv -known $(CT)/large-subset-match-known.tsv"; \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -o $(CORPUS)/step3/match0.tsv $$R > /dev/null && \
	grep -v '^#' $(CORPUS)/step3/match0.tsv | cut -f1 | sort -u > $(CORPUS)/step3/q.ids && \
	$(CRUN) $(CENV3) -q -setup $(CORPUS)/step3/setup-0.jsonl -only @$(CORPUS)/step3/q.ids $(CSAMPLES) $(CORPUS)/step3/qbase && \
	k=1; while test -e $(CORPUS)/step3/setup-$$k.jsonl; do \
	  $(CRUN) $(CENV3) -q -setup $(CORPUS)/step3/setup-$$k.jsonl -only @$(CORPUS)/step3/q.ids $(CSAMPLES) $(CORPUS)/step3/qs$$k || exit 1; k=`expr $$k + 1`; done; \
	unshare -n $(PERL) $(CT)/large-subset-threeway.pl -shellspawn . -db $(CT)/large-subset-env-control-calls.jsonl \
	  $(CORPUS)/step3/qbase $(CORPUS)/step3/qs* > $(CORPUS)/step3/threeway.txt && \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -record $(CT)/large-subset-env-control.tsv -calls $(CT)/large-subset-env-control-calls.jsonl $$Q $$R > $(CORPUS)/step3/match.txt
	$(MAKE) -f Makefile corpus-step3-class C=affects-shell E=cowroot,tmp,random,mtime,samearg0,pidns
	touch $@

# the class affects-shell, the same way (C: the class; E: the -env)
corpus-step3-class :
	@$(CROOT)
	D=$(CORPUS)/step3-$(C); mkdir -p $$D && \
	$(PERL) -Ilib $(CT)/large-subset-setups.pl -all -full 2 -one -step3 $(CSTEP3) -class $(C) $(CORPUS)/step3/deps.jsonl $$D/setup && \
	for r in base base2; do $(CRUN) -env $(E) -base $(CBASE) $(CCALLS) -setup $$D/setup-0.jsonl $(CSAMPLES) $$D/$$r || exit 1; done && \
	k=1; while test -e $$D/setup-$$k.jsonl; do $(CRUN) -env $(E) -base $(CBASE) $(CCALLS) -setup $$D/setup-$$k.jsonl $(CSAMPLES) $$D/s$$k || exit 1; k=`expr $$k + 1`; done; \
	R="-run base=$$D/base -run base2=$$D/base2"; Q="-q base=$$D/qbase -q base2=$$D/qbase"; \
	k=1; while test -d $$D/s$$k; do R="$$R -run s$$k=$$D/s$$k"; Q="$$Q -q s$$k=$$D/qs$$k"; k=`expr $$k + 1`; done; \
	P="-step3 -class $(C) -prov $(CPROV) -setups $$D/setup-samples.tsv -known $(CT)/large-subset-match-known.tsv"; \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -o $$D/match0.tsv $$R > /dev/null && \
	grep -v '^#' $$D/match0.tsv | cut -f1 | sort -u > $$D/q.ids && \
	$(CRUN) -env $(E) -base $(CBASE) $(CCALLS) -q -setup $$D/setup-0.jsonl -only @$$D/q.ids $(CSAMPLES) $$D/qbase && \
	k=1; while test -e $$D/setup-$$k.jsonl; do $(CRUN) -env $(E) -base $(CBASE) $(CCALLS) -q -setup $$D/setup-$$k.jsonl -only @$$D/q.ids $(CSAMPLES) $$D/qs$$k || exit 1; k=`expr $$k + 1`; done; \
	rm -f $(CT)/large-subset-env-$(C)-calls.jsonl; \
	unshare -n $(PERL) $(CT)/large-subset-threeway.pl -shellspawn . -db $(CT)/large-subset-env-$(C)-calls.jsonl $$D/qbase $$D/qs* > $$D/threeway.txt && \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -o $$D/match.tsv -record $(CT)/large-subset-env-$(C).tsv -calls $(CT)/large-subset-env-$(C)-calls.jsonl $$Q $$R > $$D/match.txt

#: corpus-races        (root; after corpus-step3) the races of step 3's class affects-shell (large-subset-environment.md,
#:                     12): every sample the match report calls chance by the code race, run RACERUNS times (default
#:                     20) in each environment where ShellSpawn was not as both shells; what each shell gave (record
#:                     large-subset-env-races.tsv; the report in CORPUS/races/repeat.txt; about 20 minutes, restartable)
RACERUNS = 20
corpus-races :
	@$(CROOT)
	D=$(CORPUS)/races; S=$(CORPUS)/step3-affects-shell; mkdir -p $$D && \
	$(PERL) $(CT)/large-subset-repeat.pl -ids $$S/match.tsv $$D && \
	r=1; while test $$r -le $(RACERUNS); do \
	  for f in $$D/ids-*; do test -e "$$f" || continue; e=$${f##*/ids-}; k=$${e#s}; test $$e = base && k=0; \
	    $(CRUN) -env cowroot,tmp,random,mtime,samearg0,pidns -base $(CBASE) $(CCALLS) -setup $$S/setup-$$k.jsonl -only @$$f $(CSAMPLES) $$D/r$$r/$$e > /dev/null || exit 1; done; \
	  r=`expr $$r + 1`; done; \
	A=; for d in $$D/r*/*; do test -d "$$d" || continue; A="$$A $${d##*/}=$$d"; done; \
	$(PERL) $(CT)/large-subset-repeat.pl -v -o $(CT)/large-subset-env-races.tsv $$A > $$D/repeat.txt

#: corpus-endmodes     (root; record; post-0.12, K5) ShellSpawn's wait at exit for its background jobs, each mode of
#:                     PROC_SHELLSPAWN_END (shell, the default; all; none): the samples with a background job
#:                     (large-subset-bgjobs.pl), run ENDRUNS times (default 5) in each mode in the base run's
#:                     environment, what each shell gave (large-subset-repeat.pl; record large-subset-endmodes.tsv,
#:                     the environment column is the mode; the report in CORPUS/endmodes/repeat.txt; about 10 minutes)
ENDRUNS = 5
corpus-endmodes : $(CORPUS)/samples.tsv
	@$(CROOT)
	D=$(CORPUS)/endmodes; mkdir -p $$D && \
	$(PERL) -Ilib $(CT)/large-subset-bgjobs.pl $(CSAMPLES) > $$D/bg.ids && \
	A=; for m in shell all none; do r=1; while test $$r -le $(ENDRUNS); do \
	  $(CRUN) -j $(CJ) $(CENV) -end $$m -only @$$D/bg.ids $(CSAMPLES) $$D/$$m/r$$r > /dev/null || exit 1; \
	  A="$$A $$m=$$D/$$m/r$$r"; r=`expr $$r + 1`; done; done; \
	$(PERL) $(CT)/large-subset-repeat.pl -v -o $(CT)/large-subset-endmodes.tsv $$A > $$D/repeat.txt

#: corpus-match        (root; records) section 11 of large-subset-environment.md: large-subset-match.tsv,
#:                     large-subset-match-calls.jsonl, large-subset-env-setups.tsv; the report in CORPUS/match.txt,
#:                     the former comparison of messages in CORPUS/match-raw.txt (large-subset-match-raw.md); every
#:                     snippet over all the environments it ran in: the base run, step 2's setups, and step 3's runs
#:                     (corpus-step3: the families control/ and affects-shell/, their base runs and setups)
corpus-match : $(CORPUS)/run/.done $(CORPUS)/step2/.done $(CORPUS)/step3/.done
	@$(CROOT)
	mkdir -p $(CORPUS)/match
	R="-run base=$(CORPUS)/run -run base=$(CORPUS)/step2/base -run base2=$(CORPUS)/step2/base2"; \
	Q="-q base=$(CORPUS)/match/qbase -q base2=$(CORPUS)/match/qbase"; k=1; \
	while test -d $(CORPUS)/step2/s$$k; do R="$$R -run s$$k=$(CORPUS)/step2/s$$k"; Q="$$Q -q s$$k=$(CORPUS)/match/qs$$k"; k=`expr $$k + 1`; done; \
	S=; T3=; for f in control:step3 affects-shell:step3-affects-shell; do F=$${f%%:*}; D=$(CORPUS)/$${f#*:}; \
	  S="$$S -setups $$F=$$D/setup-samples.tsv"; T3="$$T3 $$D/qbase $$D/qs*"; \
	  R="$$R -run $$F/base=$$D/base -run $$F/base2=$$D/base2"; Q="$$Q -q $$F/base=$$D/qbase -q $$F/base2=$$D/qbase"; k=1; \
	  while test -d $$D/s$$k; do R="$$R -run $$F/s$$k=$$D/s$$k"; test -d $$D/qs$$k && Q="$$Q -q $$F/s$$k=$$D/qs$$k"; k=`expr $$k + 1`; done; done; \
	P="-prov $(CPROV) -setups $(CORPUS)/step2/setup-samples.tsv $$S -known $(CT)/large-subset-match-known.tsv -ai $(CAI)"; \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -o $(CORPUS)/match/match0.tsv $$R > /dev/null && \
	grep -v '^#' $(CORPUS)/match/match0.tsv | cut -f1 | sort -u > $(CORPUS)/match/q.ids && \
	$(CRUN) $(CENV) -q -workers-from $(CORPUS)/run -only @$(CORPUS)/match/q.ids $(CSAMPLES) $(CORPUS)/match/qbase && \
	k=1; while test -e $(CORPUS)/step2/setup-$$k.jsonl; do \
	  $(CRUN) $(CENV) -q -setup $(CORPUS)/step2/setup-$$k.jsonl -only @$(CORPUS)/match/q.ids $(CSAMPLES) $(CORPUS)/match/qs$$k || exit 1; k=`expr $$k + 1`; done; \
	unshare -n $(PERL) $(CT)/large-subset-threeway.pl -shellspawn . -db $(CT)/large-subset-match-calls.jsonl \
	  $(CORPUS)/match/qbase $(CORPUS)/match/qs* $$T3 > $(CORPUS)/match/threeway.txt && \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -o $(CT)/large-subset-match.tsv -calls $(CT)/large-subset-match-calls.jsonl $$Q $$R > $(CORPUS)/match.txt && \
	$(PERL) $(CT)/large-subset-matchreport.pl $$P -raw -record $(CT)/large-subset-env-setups.tsv -calls $(CT)/large-subset-match-calls.jsonl $$Q $$R > $(CORPUS)/match-raw.txt

#: corpus-rereport     (root; records) the reports and records of the stored runs in CORPUS made again with this
#:                     tree's tools, no shell run (large-subset-rereport.sh): after a change of a report tool or of
#:                     large-subset-match-known.tsv, or for a collection of Proc-Spawner-results unpacked into CORPUS;
#:                     the records the runs write themselves (three-way, calls) stay; afterwards make corpus-stamp
corpus-rereport : pure_all
	@$(CROOT)
	PERL=$(PERL) sh $(CT)/large-subset-rereport.sh $(CORPUS)

#: corpus-stamp        (record) LABEL=DATE-NAME RUN=COMMIT [TOOLS=COMMIT] [RESULTS=DIR] [RECORDS='FILE...' or -all]:
#:                     after the runs are stored as proc-spawner/LABEL in Proc-Spawner-results, which runs and which
#:                     code made each record (large-subset-tables-used.tsv; large-subset-stamp.pl; checked by t/records.t
#:                     and make docs-check); by default the records whose content changed; TOOLS: default HEAD
corpus-stamp :
	$(PERL) $(CT)/large-subset-stamp.pl -label "$(LABEL)" -run "$(RUN)" -tools "$(TOOLS)" -results "$(RESULTS)" $(RECORDS)

#: corpus-html         (record) large-subset-state.md.html from large-subset-state.md (the Markdeep copy)
corpus-html :
	f=doc/large-subset/large-subset-state.md; { echo '<meta charset="utf-8">'; cat $$f; tail -n 2 $$f.html; } > $$f.html.new && mv $$f.html.new $$f.html

#: probe-fuzz          random strings of large-subset pieces in dash, bash --posix and ShellSpawn, the differences listed
#:                     (large-subset-difffuzz.pl; FUZZ="-n 300 -seed 1"; 25 seconds per 300; add -j 4 for 4 workers: 8 seconds)
FUZZ = -n 300 -seed 1
probe-fuzz : pure_all
	$(PERL) $(CT)/large-subset-difffuzz.pl $(FUZZ)
#: probe-values        the assumptions of X27's step 3 probed with odd values in dash, bash --posix and ShellSpawn: passthrough
#:                     and splitglob (large-subset-valueprobe.pl; 1 minute; large-subset-environment.md, section 12)
probe-values : pure_all
	$(PERL) $(CT)/large-subset-valueprobe.pl
#: probe-stress        the executor under stress: children ending while our Perl code runs (t/stress.t; 20 seconds)
probe-stress : pure_all
	RELEASE_TESTING=1 $(PERL) -Iblib/lib -Iblib/arch t/stress.t
#: probe-memory        the resident size over 1,500 runs of the large constructs stays flat (t/memory.t; Linux)
probe-memory : pure_all
	RELEASE_TESTING=1 $(PERL) -Iblib/lib -Iblib/arch t/memory.t

#: docs-check          the parts of the documents whose inputs (records, reports, scripts) changed since they were
#:                     last brought in line, with what to redo (doc/docs-sync.tsv); and the records against the runs
#:                     that made them (t/records.t: large-subset-tables-used.tsv, make corpus-stamp); status 1 if any
docs-check :
	@$(PERL) doc/docs-sync.pl check; a=$$?; RELEASE_TESTING=1 prove t/records.t; b=$$?; test $$a = 0 && test $$b = 0
#: docs-synced         DOC=FILE [PART='...']: after bringing it in line by hand, record its inputs' hashes
docs-synced :
	@$(PERL) doc/docs-sync.pl synced "$(DOC)" "$(PART)"
#: docs-map            which part of which document draws on what
docs-map :
	@$(PERL) doc/docs-sync.pl map

#: corpus-all          all of the above in order, step 3 and its races included (many hours; root): what to
#:                     run again after a change of ours (lib/) or of the runner (large-subset-runcompare.pl)
corpus-all : corpora corpus-pool-a-check corpus-parse corpus-provenance corpus-shells corpus-run corpus-qrun \
  corpus-calls corpus-runreport corpus-threeway corpus-builtins corpus-env-variants corpus-step2 corpus-step3 corpus-races corpus-endmodes corpus-match

#: corpus-clean        remove CORPUS (the runs too: hours of work)
corpus-clean :
	rm -rf $(CORPUS)

.PHONY : corpus-help corpora corpus-pool-a-check corpus-pool-a corpus-samples corpus-scan corpus-parse corpus-digest \
  corpus-shells corpus-provenance corpus-run corpus-qrun corpus-calls corpus-runreport corpus-threeway corpus-builtins \
  corpus-env-variants corpus-step2 corpus-step3 corpus-step3-class corpus-races corpus-endmodes corpus-match corpus-rejected corpus-rejected-envs corpus-rereport corpus-stamp corpus-html corpus-all corpus-clean docs-check docs-synced docs-map \
  probe-fuzz probe-values probe-stress probe-memory
