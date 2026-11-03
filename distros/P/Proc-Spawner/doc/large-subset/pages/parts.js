// Parts menu: one button per part in the "Filters" row; hover or press shows the part's items.
// The "Parts" label is a button too: it shows all items, under a heading per part.
// row: the Filters row element; groups: [{letter, short, name}]; items: [{id, title, group: letter}]
// jumpTo(id): the existing item-link jump; iconFor(id): current mark icon or "".
// isShown(id): whether the current filter shows the item.
function buildParts(row, groups, items, jumpTo, iconFor, isShown) {
  if (groups.length < 2) return;
  const wrap = document.createElement("span");
  wrap.className = "parts";
  const label = document.createElement("button");
  label.type = "button";
  label.className = "blab bar-label parts-all"; // looks like the "Filters" label, not like a button
  label.dataset.part = "*"; label.title = "All items, by part";
  label.textContent = "Parts";
  const menu = document.createElement("div");
  menu.className = "part-menu"; menu.hidden = true; menu.setAttribute("role", "menu");
  document.body.append(menu);
  let openBtn = null, pinned = false, timer = 0;
  const later = (fn, ms) => { clearTimeout(timer); timer = setTimeout(fn, ms); };

  function place(btn) {
    const r = btn.getBoundingClientRect(), W = innerWidth, H = innerHeight;
    menu.style.width = Math.min(448, W - 16) + "px";
    const below = H - r.bottom - 12, above = r.top - 12;
    const up = below < 160 && above > below;
    menu.style.maxHeight = Math.max(120, up ? above : below) + "px";
    menu.style.top = up ? "" : r.bottom + 4 + "px";
    menu.style.bottom = up ? H - r.top + 4 + "px" : "";
    menu.style.left = Math.max(8, Math.min(r.left, W - menu.offsetWidth - 8)) + "px";
  }
  function open(btn, pin, focusFirst) {
    clearTimeout(timer);
    if (openBtn && openBtn !== btn) openBtn.setAttribute("aria-expanded", "false");
    const all = btn.dataset.part === "*";
    menu.replaceChildren();
    for (const g of groups) {
      if (!all && g.letter !== btn.dataset.part) continue;
      const head = document.createElement("div");
      head.className = "part-head"; head.textContent = g.letter + " — " + g.name;
      menu.append(head);
      for (const it of items.filter(i => i.group === g.letter)) {
        const e = document.createElement("button");
        e.type = "button"; e.className = "part-entry"; e.setAttribute("role", "menuitem");
        if (!isShown(it.id)) { e.classList.add("filtered-out"); e.title = "Hidden by the current filter; opening it switches to All"; }
        const icon = document.createElement("span"); icon.className = "pe-icon"; icon.textContent = iconFor(it.id) || "";
        const id = document.createElement("b"); id.textContent = it.id;
        const t = document.createElement("span"); t.className = "pe-title"; t.textContent = it.title;
        e.append(icon, id, t);
        e.addEventListener("click", () => { close(); jumpTo(it.id); });
        menu.append(e);
      }
    }
    menu.hidden = false; openBtn = btn; pinned = pin;
    btn.setAttribute("aria-expanded", "true");
    place(btn);
    if (focusFirst) menu.querySelector(".part-entry")?.focus();
  }
  function close(refocus) {
    clearTimeout(timer);
    if (!openBtn) return;
    openBtn.setAttribute("aria-expanded", "false");
    if (refocus) openBtn.focus();
    menu.hidden = true; openBtn = null; pinned = false;
  }

  const buttons = [label];
  for (const g of groups) {
    const b = document.createElement("button");
    b.type = "button"; b.className = "part-btn"; b.dataset.part = g.letter; b.title = g.name;
    const L = document.createElement("b"); L.textContent = g.letter;
    b.append(L, " " + g.short);
    buttons.push(b);
  }
  const lead = document.createElement("span");   // keeps "Parts" on one line with the first part button
  lead.className = "parts-lead";
  wrap.append(lead);
  for (const b of buttons) {
    b.setAttribute("aria-haspopup", "menu"); b.setAttribute("aria-expanded", "false");
    b.addEventListener("click", ev => {
      if (openBtn === b && pinned) return close();
      open(b, true, ev.detail === 0);     // detail 0: pressed from the keyboard
    });
    b.addEventListener("pointerenter", ev => {
      if (ev.pointerType !== "mouse" || pinned) return;
      later(() => open(b, false, false), 120);
    });
    b.addEventListener("pointerleave", ev => {
      if (ev.pointerType === "mouse" && !pinned) later(close, 250);
    });
    b.addEventListener("keydown", ev => {
      if (ev.key === "ArrowDown") { ev.preventDefault(); open(b, true, true); }
    });
    (b === label || b === buttons[1] ? lead : wrap).append(b);
  }
  menu.addEventListener("pointerenter", () => { if (!pinned) clearTimeout(timer); });
  menu.addEventListener("pointerleave", ev => { if (ev.pointerType === "mouse" && !pinned) later(close, 250); });
  menu.addEventListener("keydown", ev => {
    const es = [...menu.querySelectorAll(".part-entry")], i = es.indexOf(document.activeElement);
    if (ev.key === "ArrowDown" || ev.key === "ArrowUp") {
      ev.preventDefault();
      const n = es.length, j = i < 0 ? (ev.key === "ArrowDown" ? 0 : n - 1)
                                     : (i + (ev.key === "ArrowDown" ? 1 : n - 1)) % n;
      es[j]?.focus();
    }
  });
  document.addEventListener("pointerdown", ev => {
    if (openBtn && !menu.contains(ev.target) && !openBtn.contains(ev.target)) close();
  });
  document.addEventListener("keydown", ev => { if (ev.key === "Escape" && openBtn) close(true); });
  menu.addEventListener("focusout", ev => {
    if (openBtn && !menu.contains(ev.relatedTarget) && ev.relatedTarget !== openBtn && ev.relatedTarget) close();
  });
  addEventListener("resize", () => { if (openBtn) place(openBtn); });
  addEventListener("scroll", () => { if (openBtn) place(openBtn); }, { capture: true, passive: true });
  row.append(wrap);
}
