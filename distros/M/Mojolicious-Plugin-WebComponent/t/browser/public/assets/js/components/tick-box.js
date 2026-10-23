class TickBox extends HTMLElement {
    constructor() {
        super();
        const shadowRoot = this.attachShadow({mode: 'open'});
        let tmpl;
        shadowRoot.appendChild(tmpl.content.cloneNode(true));
    }
    connectedCallback() { this.dataset.script = 'ok'; }
}
customElements.define('tick-box', TickBox);
