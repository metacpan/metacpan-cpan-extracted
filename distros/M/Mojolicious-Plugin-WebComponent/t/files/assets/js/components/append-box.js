// no template marker: the template is injected before the appendChild line
class AppendBox extends HTMLElement {
    constructor() {
        super();
        const shadowRoot = this.attachShadow({mode: 'open'});
        shadowRoot.appendChild(tmpl.content.cloneNode(true));
    }
}
customElements.define('append-box', AppendBox);
