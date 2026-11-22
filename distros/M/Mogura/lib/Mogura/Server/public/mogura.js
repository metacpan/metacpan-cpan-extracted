'use strict';

const editableTagClasses = 'inline-flex max-w-full items-center rounded-full border border-slate-200 bg-slate-100 px-2.5 py-0.5 text-xs text-slate-700 wrap-anywhere gap-1.5 pr-1';
const removeTagClasses = 'size-7 shrink-0 cursor-pointer rounded-full text-lg leading-none text-slate-500 hover:bg-slate-200 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-50';

for (const select of document.querySelectorAll('[data-language-select]')) {
  select.addEventListener('change', () => select.form.requestSubmit());
}

// Collect tags as separate values. Enter adds a chip without submitting the
// scan form; IME confirmation remains available for Japanese input.
for (const editor of document.querySelectorAll('[data-tag-input]')) {
  const input = editor.querySelector('[name="new_tag"]');
  const container = editor.querySelector('[data-initial-tags]');
  const status = editor.querySelector('[data-tag-input-status]');
  const form = editor.closest('form');

  function addTag() {
    const value = input.value.trim();
    if (!value) return true;
    const existing = Array.from(container.querySelectorAll('input')).map(field => field.value);
    if (existing.includes(value)) {input.value = ''; return true;}
    if (existing.length >= 20 || value.length > 120) {
      status.textContent = MoguraI18n.t('tag_limit');
      return false;
    }
    const chip = document.createElement('span');
    chip.className = editableTagClasses;
    const text = document.createElement('span');
    text.className = 'min-w-0 wrap-anywhere';
    text.textContent = value;
    const field = document.createElement('input');
    field.type = 'hidden';
    field.name = 'tags';
    field.value = value;
    const remove = document.createElement('button');
    remove.className = removeTagClasses;
    remove.type = 'button';
    remove.textContent = '×';
    remove.setAttribute('aria-label', MoguraI18n.t('remove_tag', {tag: value}));
    remove.addEventListener('click', () => chip.remove());
    chip.append(text, field, remove);
    container.append(chip);
    input.value = '';
    status.textContent = '';
    return true;
  }

  editor.querySelector('[data-add-tag]').addEventListener('click', () => {addTag(); input.focus();});
  input.addEventListener('keydown', event => {
    if (event.key !== 'Enter' || event.isComposing) return;
    event.preventDefault();
    addTag();
  });
  form.addEventListener('submit', event => {
    if (!addTag()) event.preventDefault();
  });
}

// Refresh only disk controls; drafts and the submission ID stay in place.
for (const form of document.querySelectorAll('[data-scan-form]')) {
  const panel = form.querySelector('[data-inventory-panel]');
  const inventoryStatus = document.querySelector('[data-inventory-status]');
  const submit = form.querySelector('button[type="submit"]');
  let submitting = false;
  let refreshing = false;

  function updateControls() {
    const selected = form.querySelector('input[name="target"]:checked:not(:disabled)');
    submit.disabled = submitting || !selected;
  }

  async function refreshInventory() {
    if (refreshing || submitting) return;
    refreshing = true;
    try {
      const response = await fetch('/inventory' + location.search, {cache: 'no-store', signal: AbortSignal.timeout(15000)});
      if (!response.ok) throw new Error(MoguraI18n.t('inventory_refresh_failed'));
      const html = await response.text();
      // Selection may change while the request is in flight.
      const selected = form.querySelector('input[name="target"]:checked')?.value;
      const fragment = document.createElement('template');
      fragment.innerHTML = html;
      panel.replaceChildren(fragment.content);
      for (const input of panel.querySelectorAll('input[name="target"]')) {
        input.checked = input.value === selected && !input.disabled;
      }
      inventoryStatus.textContent = '';
    } catch (error) {
      inventoryStatus.textContent = MoguraI18n.t('inventory_refresh_failed');
      // An old selection must not look current after a failed refresh.
      panel.querySelectorAll('input[name="target"]').forEach(input => {input.disabled = true;});
    } finally {
      refreshing = false;
      updateControls();
    }
  }

  form.addEventListener('change', updateControls);
  form.addEventListener('submit', async event => {
    if (event.defaultPrevented) return;
    event.preventDefault();
    if (submitting) return;
    const body = new URLSearchParams(new FormData(form));
    const status = form.querySelector('[data-scan-status]');
    status.textContent = '';
    submitting = true;
    updateControls();
    submit.textContent = MoguraI18n.t('submitting');
    try {
      const response = await fetch(form.action, {
        method: 'POST', body, headers: {Accept: 'application/json'},
        signal: AbortSignal.timeout(15000)
      });
      if (!response.ok) throw new Error(await response.text());
      const result = await response.json();
      form.elements.scan_id.value = result.next_id;
      window.location.assign(result.url);
    } catch (error) {
      status.textContent = error.message;
      submitting = false;
      submit.textContent = MoguraI18n.t('start_scan');
      updateControls();
      refreshInventory();
    }
  });
  window.addEventListener('pageshow', event => {
    if (!event.persisted) return;
    submitting = false;
    submit.textContent = MoguraI18n.t('start_scan');
    updateControls();
    refreshInventory();
  });
  updateControls();
  setInterval(refreshInventory, 5000);
}

// Tag operations send only additions or one removal. Existing tags are never
// copied into an editable field, so edits in another tab are preserved.
for (const editor of document.querySelectorAll('[data-tag-editor]')) {
  const status = editor.querySelector('[data-tag-status]');
  const token = editor.querySelector('[name="csrf_token"]').value;
  const container = editor.querySelector('[data-scan-tags]');

  function tagElement(tag) {
    const chip = document.createElement('span');
    chip.className = editableTagClasses;
    const link = document.createElement('a');
    link.href = `/history?${new URLSearchParams({tag})}`;
    link.className = 'min-w-0 wrap-anywhere hover:underline';
    link.textContent = tag;
    const form = document.createElement('form');
    form.className = 'flex shrink-0';
    form.method = 'post';
    form.action = editor.dataset.action;
    form.dataset.tagOperation = '';
    for (const [name, value] of Object.entries({csrf_token: token, operation: 'remove', tag})) {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = name;
      input.value = value;
      form.append(input);
    }
    const button = document.createElement('button');
    button.className = removeTagClasses;
    button.type = 'submit';
    button.textContent = '×';
    button.setAttribute('aria-label', MoguraI18n.t('remove_tag', {tag}));
    form.append(button);
    chip.append(link, form);
    return chip;
  }

  editor.addEventListener('submit', async event => {
    const form = event.target;
    if (!form.matches('[data-tag-operation]')) return;
    event.preventDefault();
    const body = new URLSearchParams(new FormData(form));
    editor.querySelectorAll('button').forEach(button => {button.disabled = true;});
    status.textContent = MoguraI18n.t('saving');
    try {
      const response = await fetch(form.action, {
        method: 'POST', body, headers: {Accept: 'application/json'}
      });
      if (!response.ok) throw new Error(response.status === 400 ? await response.text() : MoguraI18n.t('save_failed'));
      const {tags} = await response.json();
      container.replaceChildren(...tags.map(tagElement));
      if (body.get('operation') === 'add') form.elements.tag.value = '';
      status.textContent = body.get('operation') === 'add' ? MoguraI18n.t('tag_added') : MoguraI18n.t('tag_removed');
    } catch (error) {
      status.textContent = error.message;
    } finally {
      editor.querySelectorAll('button').forEach(button => {button.disabled = false;});
    }
  });
}

// Notes are annotations: save without reloading cached result tables.
for (const form of document.querySelectorAll('[data-note-editor]')) {
  form.addEventListener('submit', async event => {
    event.preventDefault();
    const button = form.querySelector('button');
    const status = form.querySelector('[data-note-status]');
    button.disabled = true;
    status.textContent = MoguraI18n.t('saving');
    try {
      const response = await fetch(form.action, {
        method: 'POST', body: new URLSearchParams(new FormData(form)),
        headers: {Accept: 'application/json'}
      });
      if (!response.ok) throw new Error(response.status === 400 ? await response.text() : MoguraI18n.t('save_failed'));
      status.textContent = MoguraI18n.t('saved');
    } catch (error) {
      status.textContent = error.message;
    } finally {
      button.disabled = false;
    }
  });
}
