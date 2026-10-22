"""Offline tests only: no Rex, managed host, or network access."""
from __future__ import annotations
import sys
sys.dont_write_bytecode = True
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module

audit = load('rex_audit', ROOT / 'scripts' / 'audit_rexfile.py')
validator = load('rex_validator', ROOT / 'scripts' / 'validate_package.py')

class AuditTests(unittest.TestCase):
    def codes(self, text):
        return {f.rule for f in audit.audit_text(text)}

    def test_hostkey_feature(self):
        self.assertIn('REX001', self.codes("use Rex -feature => ['disable_strict_host_key_checking'];"))
    def test_hostkey_zero(self):
        self.assertIn('REX001', self.codes('strict_hostkeycheck => 0,'))
    def test_hostkey_openssh(self):
        self.assertIn('REX001', self.codes("StrictHostKeyChecking => 'no',"))
    def test_hostkey_on(self):
        self.assertNotIn('REX001', self.codes('strict_hostkeycheck => 1,'))
    def test_shell_program(self):
        self.assertIn('REX002', self.codes("run 'sh', ['-c', $user], auto_die => 0;"))
    def test_data_array(self):
        self.assertNotIn('REX002', self.codes("run 'printf', ['%s', $data], auto_die => 1;"))
    def test_shift_right(self):
        self.assertIn('REX003', self.codes('my $code = $? >> 8;'))
    def test_shift_left_assignment(self):
        self.assertIn('REX003', self.codes('$? <<= 8;'))
    def test_raw_capture(self):
        self.assertNotIn('REX003', self.codes('my $raw = $?;'))
    def test_latest(self):
        self.assertIn('REX004', self.codes("pkg 'thing', ensure => 'latest';"))
    def test_task_collision(self):
        self.assertIn('REX005', self.codes("task 'run', sub {};"))
    def test_descriptive_task(self):
        self.assertNotIn('REX005', self.codes("task 'inspect_kernel', sub {};"))
    def test_selective_import(self):
        self.assertIn('REX006', self.codes('use Rex::Commands::Run qw(run);'))
    def test_regular_helper_export(self):
        self.assertNotIn('REX006', self.codes('use Example::Plan qw(validate_plan);'))
    def test_creates(self):
        self.assertIn('REX007', self.codes("run 'true', creates => '/tmp/example';"))
    def test_forced_fs(self):
        self.assertIn('REX008', self.codes("Rex::Interface::Fs->create('LibSSH');"))
    def test_literal_secret(self):
        findings = audit.audit_text("password 'do-not-emit-this-value';")
        self.assertIn('REX009', {f.rule for f in findings})
        self.assertNotIn('do-not-emit-this-value', json.dumps([f.__dict__ for f in findings]))
    def test_secret_variable(self):
        self.assertNotIn('REX009', self.codes('password $secret;'))
    def test_full_line_comment(self):
        self.assertEqual([], audit.audit_text("  # password 'example';\n"))
    def test_pod_skipped_preserves_lines(self):
        findings = audit.audit_text("=head1 Docs\npassword 'example';\n=cut\n$? >>= 8;\n")
        self.assertEqual([(4, 'REX003')], [(f.line, f.rule) for f in findings])
    def test_empty(self):
        self.assertEqual([], audit.audit_text(''))
    def test_cli_json_threshold(self):
        p = subprocess.run([sys.executable, '-B', str(ROOT/'scripts/audit_rexfile.py'), '-', '--json'],
                           input="password 'secret-example';", text=True, capture_output=True, timeout=10)
        self.assertEqual(1, p.returncode)
        payload = json.loads(p.stdout)
        self.assertTrue(payload['findings'])
        self.assertNotIn('secret-example', p.stdout)
    def test_cli_never_threshold(self):
        p = subprocess.run([sys.executable, '-B', str(ROOT/'scripts/audit_rexfile.py'), '-', '--json', '--fail-on', 'never'],
                           input="password 'fake';", text=True, capture_output=True, timeout=10)
        self.assertEqual(0, p.returncode)
    def test_cli_bad_utf8(self):
        p = subprocess.run([sys.executable, '-B', str(ROOT/'scripts/audit_rexfile.py'), '-', '--json'],
                           input=b'\xff', capture_output=True, timeout=10)
        self.assertEqual(2, p.returncode)
        self.assertTrue(json.loads(p.stdout)['input_errors'])
    def test_cli_oversized(self):
        p = subprocess.run([sys.executable, '-B', str(ROOT/'scripts/audit_rexfile.py'), '-', '--json'],
                           input=b'x'*(audit.MAX_BYTES+1), capture_output=True, timeout=10)
        self.assertEqual(2, p.returncode)

class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for name in validator.REQUIRED:
            path = self.root/name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('{}\n' if path.suffix == '.json' else '# Test fixture\n')
        (self.root/'SKILL.md').write_text('---\nname: rex\ndescription: Fixture only\n---\n# Rex\n')
        self.manifest()
    def tearDown(self):
        self.tmp.cleanup()
    def manifest(self):
        (self.root/'MANIFEST.json').write_text(json.dumps({'files': validator.inventory(self.root)}))
    def errors(self):
        return validator.validate(self.root)[0]
    def test_valid_fixture(self):
        self.assertEqual([], self.errors())
    def test_hash_tamper(self):
        (self.root/'README.md').write_text('changed')
        self.assertTrue(any('hash mismatch' in e for e in self.errors()))
    def test_extra_file(self):
        (self.root/'extra.txt').write_text('extra')
        self.assertTrue(any('unmanifested' in e for e in self.errors()))
    def test_missing_file(self):
        (self.root/'README.md').unlink()
        self.assertTrue(any('missing' in e for e in self.errors()))
    def test_invalid_json(self):
        (self.root/'SOURCE_LOCK.json').write_text('{broken')
        self.manifest()
        self.assertTrue(any('invalid JSON' in e for e in self.errors()))
    def test_bad_frontmatter(self):
        (self.root/'SKILL.md').write_text('# Rex\n')
        self.manifest()
        self.assertTrue(any('frontmatter' in e for e in self.errors()))
    def test_duplicate_frontmatter_key(self):
        (self.root/'SKILL.md').write_text('---\nname: rex\nname: rex\ndescription: fixture\n---\n')
        self.manifest()
        self.assertTrue(any('duplicate' in e for e in self.errors()))
    def test_missing_link(self):
        (self.root/'README.md').write_text('[missing](missing.md)')
        self.manifest()
        self.assertTrue(any('missing link' in e for e in self.errors()))
    def test_link_escape(self):
        (self.root/'README.md').write_text('[outside](../outside.md)')
        self.manifest()
        self.assertTrue(any('escapes' in e for e in self.errors()))
    def test_remote_links_not_fetched(self):
        (self.root/'README.md').write_text('[external](https://nonexistent.example.test/doc)')
        self.manifest()
        self.assertEqual([], self.errors())
    def test_valid_local_link(self):
        (self.root/'README.md').write_text('[skill](SKILL.md)')
        self.manifest()
        self.assertEqual([], self.errors())
    def test_manifest_unsafe_path(self):
        p = self.root/'MANIFEST.json'
        data = json.loads(p.read_text())
        data['files']['../escape'] = '0'*64
        p.write_text(json.dumps(data))
        self.assertTrue(any('unsafe path' in e for e in self.errors()))
    def test_symlink_rejected(self):
        try:
            (self.root/'link.md').symlink_to(self.root/'README.md')
        except OSError as exc:
            self.skipTest(f'Symlink creation is unavailable: {exc}')
        self.assertTrue(any('symlink' in e for e in self.errors()))
    def test_safe_relative(self):
        self.assertTrue(validator.safe_relative('references/core.md'))
        for name in ['', '.', '../a', '/a', 'C:/a', r'a\b', 'a//b', 'a/./b', 'a/../b']:
            with self.subTest(name=name):
                self.assertFalse(validator.safe_relative(name))

@unittest.skipUnless(shutil.which('perl'), 'Perl unavailable')
class InspectorTests(unittest.TestCase):
    def test_inventory_json(self):
        p = subprocess.run(['perl', str(ROOT/'scripts/inspect_rex.pl')], capture_output=True, text=True, timeout=10)
        self.assertEqual(0, p.returncode, p.stderr)
        payload = json.loads(p.stdout)
        self.assertEqual({'Rex', 'Rex::LibSSH', 'Net::LibSSH', 'Net::SSH2', 'Net::OpenSSH',
                          'Net::SFTP::Foreign', 'Rex::GPU', 'Rex::Rancher'},
                         {m['module'] for m in payload['modules']})
        self.assertIn('no Rex code loaded', payload['mode'])
    def test_never_executes_module(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'Rex.pm'
            content = "package Rex; our $VERSION = '9.999'; BEGIN { die 'MUST_NOT_EXECUTE'; } 1;\n"
            path.write_text(content)
            p = subprocess.run(['perl', str(ROOT/'scripts/inspect_rex.pl'), '--lib', tmp], capture_output=True, text=True, timeout=10)
            self.assertEqual(0, p.returncode, p.stderr)
            rex = json.loads(p.stdout)['modules'][0]
            self.assertEqual('9.999', rex['version_literal'])
            self.assertEqual(hashlib.sha256(content.encode()).hexdigest(), rex['sha256'])
            self.assertNotIn('MUST_NOT_EXECUTE', p.stderr)

class EvaluationSchemaTests(unittest.TestCase):
    def test_cases_are_unique_and_complete(self):
        data = json.loads((ROOT/'evals/cases.json').read_text())
        self.assertEqual('specification_only_not_executed_against_an_agent', data['status'])
        cases = data['cases']
        self.assertEqual(20, len(cases))
        self.assertEqual(len(cases), len({c['id'] for c in cases}))
        self.assertTrue(all(c['prompt'] and c['required'] and c['forbidden'] for c in cases))

if __name__ == '__main__':
    unittest.main()
