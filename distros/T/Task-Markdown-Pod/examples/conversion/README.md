# Conversion toolchain

Run the commands from a disposable copy of this directory:

```sh
cp -R . /tmp/task-markdown-pod-example
cd /tmp/task-markdown-pod-example
markpod --inplace lib/Example.pm
perldoc lib/Example.pm
docbook-convert --pandoc doc/guide.xml > doc/guide.md
```

`lib/Example.pm.md` is converted to POD and merged into `lib/Example.pm`.
`doc/guide.xml` is converted to Markdown; that Markdown can then be used as
authored documentation or as input to the same Markdown/POD workflow.

The equivalent Perl entry points are in `convert.pl`:

```sh
perl convert.pl
```
