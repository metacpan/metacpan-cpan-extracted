class InlineBox extends HTMLElement {
    constructor() { super(); this.attachShadow({mode: 'open'}).innerHTML = '<b id="in">inline ok</b>'; }
}
customElements.define('inline-box', InlineBox);
