#!/usr/bin/env python3
"""Optional Chromium end-to-end smoke tests (requires Python playwright)."""
from pathlib import Path
from tempfile import TemporaryDirectory
from subprocess import run
import shutil
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]

def check():
    with TemporaryDirectory() as folder:
        output = Path(folder)/'demo.html'
        proc = run(['perl',str(ROOT/'bin/perl-codemap'),'--parser','lite','--root',
                    str(ROOT/'examples/sample'),'--output',str(output)],check=True,capture_output=True,text=True)
        assert output.stat().st_size > 10000, proc.stdout
        with sync_playwright() as p:
            browser = p.chromium.launch(
                headless=True,
                executable_path=shutil.which('chromium') or shutil.which('google-chrome') or None,
                args=['--no-sandbox', '--disable-dev-shm-usage'],
            )
            page = browser.new_page(viewport={'width': 1380, 'height': 920})
            failures = []
            page.on('pageerror', lambda e: failures.append(str(e)))
            page.set_content(output.read_text(), wait_until='load')
            assert page.locator('.node').count() >= 12
            assert page.locator('.edge').count() >= 12
            assert '13' in page.locator('#stats').inner_text()
            page.locator('#q').fill('start')
            assert page.locator('#fns .fn').count() >= 1
            page.locator('#fns .fn a.name').first.click()
            assert page.locator('#source-modal').is_visible()
            assert page.locator('#source-lines .token').count() >= 1
            assert page.locator('.source-row.target').count() == 1
            page.locator('#source-jump').fill('3')
            page.locator('#source-go').click()
            assert page.locator('.source-row.target .line-no').inner_text() == '3'
            page.locator('#source-close').click()
            assert not page.locator('#source-modal').is_visible()
            page.locator('#home').click()
            page.locator('.node').first.click()
            assert 'Dependencies /' in page.locator('#breadcrumb').inner_text()
            assert not failures, failures
            browser.close()
        print('Chromium end-to-end checks passed')

if __name__ == '__main__':
    check()
