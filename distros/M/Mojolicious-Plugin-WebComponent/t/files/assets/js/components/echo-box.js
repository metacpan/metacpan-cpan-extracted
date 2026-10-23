customElements.define('echo-box', class extends HTMLElement {
    constructor() {
        super();
        const shadowRoot = this.attachShadow({mode: 'open'});
        let tmpl;
        shadowRoot.appendChild(tmpl.content.cloneNode(true));
    }
});
